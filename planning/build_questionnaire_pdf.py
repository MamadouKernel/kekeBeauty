from pathlib import Path
from xml.sax.saxutils import escape
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, KeepTogether, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from build_questionnaire import sections

OUT = Path(__file__).resolve().parent.parent / 'output' / 'questionnaire'
PDF = OUT / 'Questionnaire_decisions_Keke_Beauty.pdf'
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='QuestionTitle', parent=styles['Title'], fontName='Helvetica-Bold', fontSize=17, leading=21, textColor=HexColor('#171717'), alignment=TA_LEFT, spaceAfter=12))
styles.add(ParagraphStyle(name='SectionBlack', parent=styles['Heading2'], fontName='Helvetica-Bold', fontSize=11, leading=14, textColor=HexColor('#171717'), spaceBefore=13, spaceAfter=8))
styles.add(ParagraphStyle(name='QuestionBlack', parent=styles['BodyText'], fontName='Helvetica-Bold', fontSize=9.5, leading=13, spaceAfter=3))
styles.add(ParagraphStyle(name='BodyFrench', parent=styles['BodyText'], fontName='Helvetica', fontSize=9, leading=12.5, spaceAfter=7))
styles.add(ParagraphStyle(name='SmallFrench', parent=styles['BodyText'], fontName='Helvetica', fontSize=8.2, leading=11, spaceAfter=6))
story = [Paragraph('Questionnaire de cadrage Keke Beauty', styles['QuestionTitle']),
         Paragraph('À remplir avec le commanditaire avant de valider les règles de gestion, le MCD, le calendrier et les fournisseurs. Les questions couvrent les décisions laissées ouvertes par le cahier des charges actuel.', styles['BodyFrench'])]
meta = Table([['Nom du répondant :', 'Fonction :'], ['Date :', 'Version des réponses :']], colWidths=[8.2*cm,8.2*cm], rowHeights=[.85*cm,.85*cm])
meta.setStyle(TableStyle([('BOX',(0,0),(-1,-1),.4,HexColor('#777777')),('INNERGRID',(0,0),(-1,-1),.3,HexColor('#bbbbbb')),('VALIGN',(0,0),(-1,-1),'MIDDLE'),('LEFTPADDING',(0,0),(-1,-1),8)]))
story += [meta, Spacer(1,10), Paragraph('Inscrivez votre réponse sur les lignes. Si la décision reste ouverte, précisez qui la prendra et quand.', styles['BodyFrench'])]
for heading, questions in sections:
    story.append(Paragraph(escape(heading), styles['SectionBlack']))
    for num, q, why in questions:
        story.append(KeepTogether([
            Paragraph(escape(num+'  '+q), styles['QuestionBlack']),
            Paragraph('Pourquoi cette réponse compte : '+escape(why), styles['SmallFrench']),
            Paragraph('Réponse : ________________________________________________________________', styles['BodyFrench']),
            Spacer(1,6)]))
story += [Paragraph('Validation des décisions', styles['SectionBlack']),
          Paragraph('Décisions encore ouvertes et responsable : _________________________________________________', styles['BodyFrench']),
          Paragraph('Date de validation prévue : _____________________________________________________________', styles['BodyFrench']),
          Paragraph('Nom et accord du commanditaire : _______________________________________________________', styles['BodyFrench'])]

def page_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont('Helvetica',8)
    canvas.setFillColor(HexColor('#555555'))
    canvas.drawString(2*cm,1.1*cm,'Keke Beauty  |  Questionnaire de cadrage')
    canvas.drawRightString(A4[0]-2*cm,1.1*cm,str(doc.page))
    canvas.restoreState()

SimpleDocTemplate(str(PDF), pagesize=A4, rightMargin=2*cm,leftMargin=2*cm,topMargin=1.7*cm,bottomMargin=1.7*cm).build(story,onFirstPage=page_footer,onLaterPages=page_footer)
print(PDF)
