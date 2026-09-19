from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "output" / "pdf" / "Keke_Beauty_Preparation_Client_Points_Bloquants.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

PURPLE = colors.HexColor("#74388A")
DARK = colors.HexColor("#242127")
MUTED = colors.HexColor("#625D66")
LILAC = colors.HexColor("#F3EDF7")
BORDER = colors.HexColor("#E4E1E7")
RED = colors.HexColor("#B42318")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="Cover", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=27, leading=32, textColor=PURPLE, alignment=TA_CENTER, spaceAfter=10))
styles.add(ParagraphStyle(name="Sub", parent=styles["BodyText"], fontSize=11, leading=16, textColor=MUTED, alignment=TA_CENTER))
styles.add(ParagraphStyle(name="H1x", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=18, leading=23, textColor=PURPLE, spaceBefore=4, spaceAfter=10))
styles.add(ParagraphStyle(name="H2x", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=12.5, leading=16, textColor=DARK, spaceBefore=8, spaceAfter=5))
styles.add(ParagraphStyle(name="Bodyx", parent=styles["BodyText"], fontSize=9.5, leading=14, textColor=DARK, spaceAfter=6))
styles.add(ParagraphStyle(name="Smallx", parent=styles["BodyText"], fontSize=8, leading=11, textColor=MUTED))
styles.add(ParagraphStyle(name="TableHeader", parent=styles["Smallx"], fontName="Helvetica-Bold", textColor=colors.white))
styles.add(ParagraphStyle(name="Warn", parent=styles["BodyText"], fontSize=9, leading=13, textColor=RED, backColor=colors.HexColor("#FEF3F2"), borderColor=colors.HexColor("#FECACA"), borderWidth=0.5, borderPadding=7, spaceAfter=10))

items = [
    ("1. SMS et OTP", "Choisir le fournisseur SMS et ouvrir un compte sandbox puis production.", "Nom du fournisseur, endpoint HTTPS, méthode d'authentification, Sender ID autorisé, pays couverts, quotas et coûts.", "Responsable produit + technique", "Avant la recette OTP/SMS réelle", "Adaptateur, quotas, file d'envoi, déduplication et reprise déjà implémentés."),
    ("2. Paiements", "Choisir l'agrégateur et contractualiser le compte marchand.", "Canaux Wave/Orange/MTN/Moov, Visa/Mastercard, devise XOF, clés sandbox, webhook, règles de remboursement et délais de règlement.", "Direction + finance + technique", "Avant le lot abonnements", "Contrat de configuration, initiation JSON et vérification HMAC déjà préparés."),
    ("3. KYC et données personnelles", "Valider le prestataire ou le stockage privé ainsi que la politique de conservation.", "Documents acceptés, taille, durée de conservation, rôles autorisés, suppression, base juridique et responsable de validation.", "Direction + juridique/DPO", "Avant l'onboarding partenaire", "Stockage privé configurable, liste blanche MIME et absence d'URL publique déjà prévus."),
    ("4. Hébergement et exploitation", "Choisir l'hébergeur, la région et le domaine.", "Nom de domaine, environnements recette/production, certificat HTTPS, sauvegardes, supervision, RPO/RTO, responsables d'astreinte.", "Direction + technique", "Avant recette publique", "Le démarrage production refuse déjà une configuration sans garanties minimales."),
    ("5. Cartographie et itinéraires", "Valider Google Maps ou Mapbox et la stratégie Yango.", "Clés/API, quotas, facturation, format de deep link Yango confirmé et appareils cibles.", "Produit + technique", "Avant recette annuaire réelle", "Lien HTTPS configurable et solution de repli disponibles."),
    ("6. Identité visuelle", "Choisir un seul logo parmi les quatre propositions.", "Fichier SVG ou PNG transparent, variantes claire/sombre, zone de protection et droits d'utilisation.", "Direction / marque", "Avant validation graphique finale", "Le nom texte et les tokens violets Stitch sont utilisés sans imitation du symbole."),
    ("7. Catalogue et zones", "Fournir les données réelles de lancement.", "Pays, régions, villes, communes, catégories, salons pilotes, prestations, prix, horaires, coordonnées GPS et médias autorisés.", "Produit + partenaires pilotes", "Avant recette métier", "Imports et interfaces peuvent être préparés avec des données isolées."),
    ("8. Règles commerciales", "Valider les offres et conditions d'abonnement.", "Prix, devise, taxes, engagement de 12 mois, mensualité/annuité, grâce, renouvellement, suspension et traitement des RDV existants.", "Direction + finance + produit", "Avant paiements", "Toutes les valeurs resteront configurables et historisées."),
    ("9. Gouvernance Scrum", "Nommer les rôles et les valideurs.", "Product Owner, Scrum Master, responsable KYC, responsable financier, responsable production et disponibilité pour Reviews.", "Sponsor projet", "Dès maintenant", "Le backlog et la Definition of Done sont déjà documentés."),
    ("10. Maquettes Stitch restantes", "Faire valider les parcours partenaire, KYC, paiement et administration.", "Écrans mobile 390 px et desktop 1440 px, états vide/erreur/succès, logo final et contenus approuvés.", "Produit + design", "Avant chaque lot UI", "DESIGN.md et la série client PWA 01 servent de référence."),
]

def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(BORDER)
    canvas.line(18 * mm, 15 * mm, 192 * mm, 15 * mm)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(18 * mm, 10 * mm, "Keke Beauty - Préparation client - 17 septembre 2026")
    canvas.drawRightString(192 * mm, 10 * mm, f"Page {doc.page}")
    canvas.restoreState()

doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=18*mm, leftMargin=18*mm, topMargin=18*mm, bottomMargin=22*mm, title="Keke Beauty - Préparation client", author="Keke Beauty")
story = [Spacer(1, 30*mm), Paragraph("Keke Beauty", styles["Cover"]), Paragraph("Préparation client - points bloquants et informations à fournir", styles["Sub"]), Spacer(1, 14*mm)]
story.append(Paragraph("But du document", styles["H1x"]))
story.append(Paragraph("Permettre au client de préparer les décisions, comptes et contenus nécessaires aux prochains lots. Un point bloquant n'empêche pas les développements configurables, mais il empêche la recette réelle ou la mise en production du domaine concerné.", styles["Bodyx"]))
story.append(Paragraph("Important : ne jamais envoyer de clé API, mot de passe, OTP ou pièce d'identité dans un e-mail, ClickUp ou ce PDF. Les secrets seront saisis dans le gestionnaire de secrets de l'environnement cible.", styles["Warn"]))
story.append(Paragraph("Vue rapide", styles["H1x"]))
summary = [[Paragraph("Sujet", styles["TableHeader"]), Paragraph("Responsable suggéré", styles["TableHeader"]), Paragraph("Moment requis", styles["TableHeader"])]]
for title, _, _, owner, when, _ in items:
    summary.append([Paragraph(title.replace(". ", ".<br/>", 1), styles["Smallx"]), Paragraph(owner, styles["Smallx"]), Paragraph(when, styles["Smallx"])])
t = Table(summary, colWidths=[58*mm, 62*mm, 54*mm], repeatRows=1)
t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),PURPLE),("TEXTCOLOR",(0,0),(-1,0),colors.white),("GRID",(0,0),(-1,-1),0.4,BORDER),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),6),("RIGHTPADDING",(0,0),(-1,-1),6),("TOPPADDING",(0,0),(-1,-1),5),("BOTTOMPADDING",(0,0),(-1,-1),5),("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,LILAC])]))
story += [t, PageBreak(), Paragraph("Détail des préparatifs", styles["H1x"])]
for title, decision, info, owner, when, parallel in items:
    data = [[Paragraph("Décision/action",styles["Smallx"]),Paragraph(decision,styles["Smallx"])],[Paragraph("Informations attendues",styles["Smallx"]),Paragraph(info,styles["Smallx"])],[Paragraph("Responsable suggéré",styles["Smallx"]),Paragraph(owner,styles["Smallx"])],[Paragraph("Moment requis",styles["Smallx"]),Paragraph(when,styles["Smallx"])],[Paragraph("Travail déjà possible",styles["Smallx"]),Paragraph(parallel,styles["Smallx"])]]
    table=Table(data,colWidths=[42*mm,132*mm])
    table.setStyle(TableStyle([("GRID",(0,0),(-1,-1),0.35,BORDER),("BACKGROUND",(0,0),(0,-1),LILAC),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),6),("RIGHTPADDING",(0,0),(-1,-1),6),("TOPPADDING",(0,0),(-1,-1),4),("BOTTOMPADDING",(0,0),(-1,-1),4)]))
    if title.startswith("10."):
        story.append(PageBreak())
    story.append(KeepTogether([Paragraph(title, styles["H2x"]), table, Spacer(1, 5*mm)]))

story += [Paragraph("Checklist de démarrage", styles["H1x"])]
checklist = [
    "[ ] Logo final et fichiers sources approuvés",
    "[ ] Product Owner, Scrum Master et responsables métier nommés",
    "[ ] Fournisseur SMS et compte sandbox ouverts",
    "[ ] Agrégateur de paiement et compte marchand ouverts",
    "[ ] Politique KYC et protection des données validée",
    "[ ] Domaine, hébergeur, sauvegardes et supervision choisis",
    "[ ] Pays, devise, taxes, zones et catégories validés",
    "[ ] Offres, prix, engagement, grâce et renouvellement validés",
    "[ ] Salons pilotes, prestations, horaires, GPS et médias fournis",
    "[ ] Maquettes Stitch partenaire, paiement et administration validées",
]
for row in checklist:
    story.append(Paragraph(row, styles["Bodyx"]))
story += [Spacer(1, 5*mm), Paragraph("Prochaine revue recommandée", styles["H1x"]), Paragraph("Organiser une séance de 60 à 90 minutes avec le sponsor, le Product Owner, la finance, le responsable KYC/protection des données et le responsable technique. Parcourir cette checklist, affecter un propriétaire à chaque ligne et dater uniquement les décisions réellement maîtrisées.", styles["Bodyx"])]

doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
