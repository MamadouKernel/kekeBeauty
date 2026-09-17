"""Real HTTP + PostgreSQL integration tests. Isolated database, no production providers."""
import argparse
import concurrent.futures
import http.cookiejar
import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--docker', default='docker')
args = parser.parse_args()
db = 'kb_application_' + uuid.uuid4().hex[:12]
container = 'kekebeauty-merise-db-1'

def docker(*command, text=None):
    p = subprocess.run([args.docker, *command], input=text, text=True, encoding='utf-8', capture_output=True, timeout=60)
    if p.returncode: raise RuntimeError(p.stderr)
    return p.stdout

def sql(text):
    return docker('exec','-i',container,'psql','-X','-v','ON_ERROR_STOP=1','-At','-U','keke_owner','-d',db,text=text)

docker('exec',container,'createdb','-U','keke_owner',db)
for name in ['020_modele_v2.sql','030_acceptation_rdv.sql','040_identite.sql','050_actions_rdv.sql','060_creation_rdv.sql','061_annuaire.sql','070_expiration_rdv.sql']:
    sql((ROOT/'merise/mpd'/name).read_text(encoding='utf-8'))
sql((ROOT/'infra/postgres/fixture_acceptation.sql').read_text(encoding='utf-8'))
sql("UPDATE kb.compte SET telephone_normalise=CASE compte_id WHEN 1 THEN '+2250700000001' ELSE '+2250700000002' END;")
sql("""INSERT INTO kb.rendez_vous(client_id,politique_id) VALUES(1,1),(1,1),(1,1);
INSERT INTO kb.ligne_rdv SELECT n,1,1,(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+n*interval '1 hour',
(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+n*interval '1 hour'+interval '30 minutes' FROM generate_series(1,3)n;
INSERT INTO kb.allocation_rdv SELECT n,1,1,1 FROM generate_series(1,3)n;""")
password = next(x.split('=',1)[1] for x in (ROOT/'infra/postgres/.env').read_text().splitlines() if x.startswith('POSTGRES_PASSWORD='))
env = dict(os.environ, ASPNETCORE_ENVIRONMENT='Development', ASPNETCORE_URLS='http://127.0.0.1:5189',
           ConnectionStrings__KekeBeauty=f'Host=127.0.0.1;Port=55432;Database={db};Username=keke_owner;Password={password}')
log = ROOT/'src/KekeBeauty.Web/App_Data/application-tests.log'
log.parent.mkdir(exist_ok=True)
passed=[]

class Browser:
    def __init__(self):
        self.client=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    def request(self,path,data=None):
        body=None if data is None else urllib.parse.urlencode(data).encode()
        try:
            with self.client.open('http://127.0.0.1:5189'+path,body,timeout=15) as response:
                return response.status,response.read().decode(),response.url
        except urllib.error.HTTPError as response:
            return response.code,response.read().decode(),response.url
    def token(self,path='/connexion'):
        status,body,_=self.request(path)
        assert status==200,(status,body[:200])
        return re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"',body).group(1)
    def issue(self,phone):
        status,body,url=self.request('/auth/request',{'phone':phone,'__RequestVerificationToken':self.token()})
        assert status==200 and 'Code de test' in body,(status,url,body[:100])
        return re.search(r'name="challenge" value="([^"]+)"',body).group(1),re.search(r'<strong>([0-9]{6})</strong>',body).group(1),re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"',body).group(1)
    def verify(self,challenge,code,token):
        return self.request('/auth/verify',{'challenge':challenge,'code':code,'__RequestVerificationToken':token})
    def login(self,phone):
        challenge,code,token=self.issue(phone)
        status,body,url=self.verify(challenge,code,token)
        assert status==200 and url.endswith('/mes-rendez-vous'),(status,url,body[:300])
        return challenge,code,token
    def act(self,id,action,key=''):
        return self.request('/rendez-vous/action',{'id':id,'action':action,'key':key,'__RequestVerificationToken':self.token('/mes-rendez-vous')})

with log.open('w',encoding='utf-8') as stream:
    server=subprocess.Popen(['dotnet','bin/Debug/net10.0/KekeBeauty.Web.dll'],cwd=ROOT/'src/KekeBeauty.Web',env=env,stdout=stream,stderr=stream)
    try:
        for _ in range(100):
            try:
                if Browser().request('/connexion')[0]==200: break
            except (OSError,urllib.error.URLError): pass
            if server.poll() is not None: raise RuntimeError('Application failed; inspect App_Data/application-tests.log')
            time.sleep(.2)
        else: raise RuntimeError('Application startup timeout')
        anonymous=Browser()
        assert 'Connectez-vous' in anonymous.request('/mes-rendez-vous')[1]
        assert '/connexion' in anonymous.request('/rendez-vous/action',{'id':1,'action':'accepter'})[2]
        passed.append('anonymous cannot read or mutate appointments')
        assert anonymous.request('/auth/request',{'phone':'+2250700000099'})[0] in (400,403)
        passed.append('CSRF request without token rejected')
        client=Browser(); challenge,code,token=client.login('+2250700000001')
        assert 'TEST acceptance' in client.request('/mes-rendez-vous')[1]
        passed.append('OTP login and database-backed client appointments')
        assert 'erreur=code' in client.verify(challenge,code,client.token())[2]
        passed.append('OTP cannot be replayed')
        assert 'resultat=erreur' in client.act(1,'accepter')[2]
        passed.append('client cannot accept own appointment')
        manager=Browser(); manager.login('+2250700000002')
        assert 'resultat=ok' in manager.act(1,'accepter')[2]
        assert sql('SELECT etat FROM kb.rendez_vous WHERE rdv_id=1;').strip()=='accepte'
        passed.append('authorized manager acceptance through HTTP')
        assert 'resultat=ok' in manager.act(2,'refuser')[2]
        assert 'resultat=ok' in manager.act(2,'refuser')[2]
        assert sql('SELECT count(*) FROM kb.evenement_rdv WHERE rdv_id=2;').strip()=='1'
        passed.append('manager refusal is idempotent')
        assert 'resultat=erreur' in manager.act(1,'annuler','bad-owner')[2]
        passed.append('manager cannot impersonate appointment client')
        assert 'resultat=ok' in client.act(1,'annuler','cancel-1')[2]
        assert 'resultat=ok' in client.act(1,'annuler','cancel-1')[2]
        assert sql('SELECT count(*) FROM kb.modification_client WHERE rdv_id=1;').strip()=='1'
        passed.append('client cancellation and idempotent replay')
        sql("UPDATE kb.ligne_rdv SET debut=now()+interval '30 minutes',fin=now()+interval '60 minutes' WHERE rdv_id=3;")
        assert 'resultat=erreur' in client.act(3,'annuler','too-late')[2]
        passed.append('cancellation inside configured deadline rejected')
        assert 'TEST acceptance' in anonymous.request('/')[1]
        assert 'TEST acceptance' not in anonymous.request('/?q=inexistant')[1]
        passed.append('public catalogue reads published subscribed salons and filters')
        slot_page=client.request('/salons/1?prestation=1')
        assert slot_page[0]==200 and 'Créneaux disponibles' in slot_page[1] and 'datetime-local' not in slot_page[1],slot_page[1][:500]
        passed.append('server proposes selectable slots instead of free date input')
        sql("""INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES(1,'employe','Employe test',1),(1,'physique','Cabine test',1);
        INSERT INTO kb.membre_groupe VALUES(1,2),(1,3);
        INSERT INTO kb.plage_ressource(ressource_id,jour_semaine,debut,fin) SELECT r,n,'00:00','23:59' FROM unnest(ARRAY[2,3]) r CROSS JOIN generate_series(1,7)n;""")
        for version,mode in [(2,'employes'),(3,'ressources'),(4,'combinee'),(5,'globale')]:
            sql(f"INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,portee_modification) VALUES(1,{version},clock_timestamp()-interval '1 millisecond','{mode}',false,'rendez_vous');")
            mode_page=client.request('/salons/1?prestation=1')
            assert mode_page[0]==200 and 'Créneaux disponibles' in mode_page[1],(mode,mode_page[1][:500])
        passed.append('slot proposal covers global, employee, physical resource and combined capacity modes')
        start=sql("SELECT to_char(CURRENT_DATE+1,'YYYY-MM-DD')||'T15:00';").strip()
        def create(key='new-booking',start=start):
            return client.request('/rendez-vous/creer',{'salon':1,'versions':1,'start':start,'key':key,'__RequestVerificationToken':client.token('/salons/1?prestation=1')})
        result=create()
        assert 'resultat=ok' in result[2],(result[0],result[2],result[1][:500])
        assert 'resultat=ok' in create()[2]
        assert sql("SELECT count(*) FROM kb.demande_idempotente WHERE cle='new-booking';").strip()=='1'
        new_id=sql("SELECT rdv_id FROM kb.demande_idempotente WHERE cle='new-booking';").strip()
        assert sql(f'SELECT etat FROM kb.rendez_vous WHERE rdv_id={new_id};').strip()=='en_attente_salon'
        assert sql(f'SELECT count(*) FROM kb.allocation_rdv WHERE rdv_id={new_id};').strip()=='1'
        passed.append('booking creation automatically allocates capacity, awaits salon and replays safely')
        assert 'erreur=creneau' in create(start=start.replace('15:00','16:00'))[2]
        passed.append('idempotency key cannot change appointment payload')
        assert 'resultat=ok' in manager.act(new_id,'accepter')[2]
        assert 'erreur=creneau' in create('overbook')[2]
        passed.append('booking creation refuses an occupied resource')
        sql('UPDATE kb.echeance SET montant_du=2000;')
        assert 'TEST acceptance' not in anonymous.request('/')[1]
        passed.append('unpaid salon hidden immediately when configured')
        sql('UPDATE kb.echeance SET montant_du=1000;')
        sql("UPDATE kb.compte SET etat='suspendu' WHERE compte_id=1;")
        assert 'Connectez-vous' in client.request('/mes-rendez-vous')[1]
        passed.append('suspended account loses session access')
        attacker=Browser(); challenge,code,token=attacker.issue('+2250700000090')
        wrong='000000' if code!='000000' else '999999'
        for _ in range(5): assert 'erreur=code' in attacker.verify(challenge,wrong,token)[2]
        assert 'erreur=code' in attacker.verify(challenge,code,token)[2]
        passed.append('OTP locked after five wrong attempts including correct sixth attempt')
        challenge,code,token=attacker.issue('+2250700000091')
        sql(f"UPDATE kb.defi_connexion SET expire_le=now()-interval '1 minute' WHERE defi_id='{challenge}';")
        assert 'erreur=code' in attacker.verify(challenge,code,token)[2]
        passed.append('expired OTP cannot establish a session')
    finally:
        server.terminate()
        server.wait(timeout=20)
sql("UPDATE kb.compte SET etat='actif' WHERE compte_id=1;")
sql("""INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,maintien_minutes,portee_modification)
VALUES(1,6,clock_timestamp(),'globale',true,30,'client_etablissement');""")
def request_sql(key,hour):
    return f"SELECT kb.creer_rdv(1,1,ARRAY[1]::bigint[],(CURRENT_DATE+1)::timestamp AT TIME ZONE 'Africa/Abidjan'+interval '{hour} hours','{key}');"
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    first=pool.submit(sql,"SET application_name='kb_creation_first'; BEGIN; "+request_sql('race-first',17)+" SELECT pg_sleep(2); COMMIT;")
    deadline=time.monotonic()+10
    while time.monotonic()<deadline:
        if sql("SELECT count(*) FROM pg_stat_activity WHERE application_name='kb_creation_first' AND wait_event='PgSleep';").strip()=='1': break
        time.sleep(.05)
    else: raise AssertionError('Concurrent creation synchronization failed')
    second=pool.submit(sql,request_sql('race-second',17))
    first.result()
    try: second.result(); raise AssertionError('Second booking overcommitted last place')
    except RuntimeError as error: assert 'Aucune ressource disponible' in str(error),str(error)
passed.append('two concurrent blocking requests: only first obtains last place')
assert sql("SELECT count(*) FROM kb.demande_idempotente WHERE cle='race-second';").strip()=='0'
passed.append('failed creation rolls back idempotency record and appointment')
quota_id=sql(request_sql('quota',18)).strip()
try: sql(f"SELECT kb.annuler_rdv({quota_id},1,'quota-cancel');"); raise AssertionError('Shared quota bypassed')
except RuntimeError as error: assert 'Quota modifications atteint' in str(error),str(error)
passed.append('client-salon cancellation quota includes earlier appointments')
expired_id=sql("INSERT INTO kb.rendez_vous(client_id,politique_id,cree_le,expire_le) VALUES(1,6,now()-interval '2 minutes',now()-interval '1 minute') RETURNING rdv_id;").splitlines()[0]
assert sql("SELECT kb.expirer_demandes_rdv(10);").strip()=='1'
assert sql("SELECT kb.expirer_demandes_rdv(10);").strip()=='0'
assert sql(f"SELECT etat FROM kb.rendez_vous WHERE rdv_id={expired_id};").strip()=='expire'
assert sql(f"SELECT count(*) FROM kb.evenement_rdv WHERE rdv_id={expired_id} AND nature='expire';").strip()=='1'
assert sql(f"SELECT count(*) FROM kb.notification n JOIN kb.evenement_rdv e USING(evenement_id) WHERE e.rdv_id={expired_id};").strip()=='2'
passed.append('automatic expiration is idempotent and creates in-app plus SMS notifications')
print(json.dumps({'database':db,'passed':passed,'count':len(passed),'retained_for_review':True},ensure_ascii=False,indent=2))
