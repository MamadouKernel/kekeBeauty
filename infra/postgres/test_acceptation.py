"""Integration tests on an isolated, uniquely named Docker database (retained for review)."""
import argparse
import concurrent.futures
import json
import subprocess
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--docker', default='docker')
args = parser.parse_args()
container = 'kekebeauty-merise-db-1'
db = 'kb_acceptance_' + uuid.uuid4().hex[:12]

def docker(*command, input=None, check=True):
    p = subprocess.run([args.docker, *command], input=input, text=True, encoding='utf-8', capture_output=True, timeout=60)
    if check and p.returncode:
        raise RuntimeError(p.stdout + p.stderr)
    return p

def sql(text, check=True):
    return docker('exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1','-At','-U','keke_owner','-d',db, input=text,check=check)

docker('exec',container,'createdb','-U','keke_owner',db)
for name in ['020_modele_v2.sql','030_acceptation_rdv.sql']:
    sql((ROOT/'merise/mpd'/name).read_text(encoding='utf-8'))

sql((ROOT/'infra/postgres/fixture_acceptation.sql').read_text(encoding='utf-8'))

def booking(minute=600):
    r=sql(f"INSERT INTO kb.rendez_vous(client_id,politique_id) VALUES(1,1) RETURNING rdv_id;").stdout.splitlines()[0]
    sql(f"INSERT INTO kb.ligne_rdv VALUES({r},1,1,(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+interval '{minute} minutes',(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+interval '{minute+30} minutes'); INSERT INTO kb.allocation_rdv VALUES({r},1,1,1);")
    return int(r)

passed=[]
def rejects(label, query, message):
    p=sql(query,check=False)
    assert p.returncode and message in p.stderr, (label,p.stdout,p.stderr)
    passed.append(label)

r1,r2=booking(),booking()
rejects('unauthorized',f'SELECT kb.accepter_rdv({r1},1);','Non habilite')
rejects('unpaid',f"BEGIN; UPDATE kb.echeance SET montant_du=2000; SELECT kb.accepter_rdv({r1},2);",'impaye')
rejects('closed',f"BEGIN; INSERT INTO kb.exception_ouverture(etablissement_id,date_concernee,ferme) VALUES(1,CURRENT_DATE+1,true); SELECT kb.accepter_rdv({r1},2);",'Exception ouverture')
rejects('resource break',f"BEGIN; INSERT INTO kb.indisponibilite_ressource(ressource_id,debut,fin) SELECT 1,debut,fin FROM kb.ligne_rdv WHERE rdv_id={r1}; SELECT kb.accepter_rdv({r1},2);",'Ressource indisponible')

# First connection holds the salon row until explicitly released by its commit.
# Observe pg_stat_activity before starting the competing acceptance: no timing guess.
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    first=pool.submit(sql,f"SET application_name='kb_acceptance_first'; BEGIN; SELECT kb.accepter_rdv({r1},2); SELECT pg_sleep(3); COMMIT;")
    deadline=time.monotonic()+10
    while time.monotonic()<deadline:
        if sql("SELECT count(*) FROM pg_stat_activity WHERE application_name='kb_acceptance_first' AND wait_event='PgSleep';").stdout.strip()=='1': break
        time.sleep(.05)
    else: raise AssertionError('First transaction did not reach synchronization point')
    second=pool.submit(sql,f'SELECT kb.accepter_rdv({r2},2);',False)
    first.result()
    p=second.result()
    assert p.returncode and 'Capacite insuffisante' in p.stderr,p.stderr
passed.append('concurrent last place: only first accepted')
assert sql(f'SELECT etat FROM kb.rendez_vous WHERE rdv_id={r2};').stdout.strip()=='en_attente_salon'
assert sql(f'SELECT kb.accepter_rdv({r1},2);').stdout.strip()=='deja_accepte'
assert sql(f'SELECT count(*) FROM kb.notification n JOIN kb.evenement_rdv e USING(evenement_id) WHERE e.rdv_id={r1};').stdout.strip()=='2'
passed.append('idempotent replay: one event and two channels')
r3=booking(630)
assert sql(f'SELECT kb.accepter_rdv({r3},2);').stdout.strip()=='accepte'
passed.append('adjacent interval accepted')
sql('UPDATE kb.ressource SET capacite=2 WHERE ressource_id=1;')
assert sql(f'SELECT kb.accepter_rdv({r2},2);').stdout.strip()=='accepte'
r4=booking()
rejects('capacity two respected',f'SELECT kb.accepter_rdv({r4},2);','Capacite insuffisante')
# A one-hour booking overlaps two successive half-hour appointments, but never
# more than one at the same instant. A naive sum of overlaps would reject it.
sql("INSERT INTO kb.version_variante(variante_id,date_effet,duree_minutes,montant,devise) VALUES(1,now()+interval '1 day',60,9000,'XOF');")
r5=booking(660); r6=booking(690)
sql(f'SELECT kb.accepter_rdv({r5},2); SELECT kb.accepter_rdv({r6},2);')
r7=booking(660)
sql(f"UPDATE kb.ligne_rdv SET version_variante_id=2,fin=fin+interval '30 minutes' WHERE rdv_id={r7};")
assert sql(f'SELECT kb.accepter_rdv({r7},2);').stdout.strip()=='accepte'
passed.append('capacity counted per subinterval, not sum of all overlaps')
sql("""INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,maintien_minutes,portee_modification)
VALUES(1,2,now()+interval '1 day','globale',true,10,'rendez_vous');
UPDATE kb.ressource SET capacite=1 WHERE ressource_id=1;""")
def held_booking(minute, expired=False):
    expiration="now()-interval '1 minute'" if expired else "now()+interval '10 minutes'"
    r=int(sql(f"INSERT INTO kb.rendez_vous(client_id,politique_id,cree_le,expire_le) VALUES(1,2,now()-interval '20 minutes',{expiration}) RETURNING rdv_id;").stdout.splitlines()[0])
    sql(f"INSERT INTO kb.ligne_rdv VALUES({r},1,1,(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+interval '{minute} minutes',(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+interval '{minute+30} minutes'); INSERT INTO kb.allocation_rdv VALUES({r},1,1,1);")
    return r
hold=held_booking(780); candidate=booking(780)
rejects('unexpired hold consumes capacity',f'SELECT kb.accepter_rdv({candidate},2);','Capacite insuffisante')
assert sql(f'SELECT kb.accepter_rdv({hold},2);').stdout.strip()=='accepte'
passed.append('own hold not double counted')
expired=held_booking(840,True); candidate=booking(840)
rejects('expired request cannot be accepted',f'SELECT kb.accepter_rdv({expired},2);','Maintien expire')
assert sql(f'SELECT kb.accepter_rdv({candidate},2);').stdout.strip()=='accepte'
passed.append('expired hold releases availability')
assert sql(f'SELECT count(*) FROM kb.evenement_rdv WHERE rdv_id={r1};').stdout.strip()=='1'
print(json.dumps({'database':db,'passed':passed,'count':len(passed),'retained_for_review':True},ensure_ascii=False,indent=2))
