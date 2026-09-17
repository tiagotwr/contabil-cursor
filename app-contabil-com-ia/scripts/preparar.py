"""Cria e atualiza o schema sem alterar os dados já existentes."""
import json
import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from flask_bcrypt import generate_password_hash
from psycopg2.extras import Json
from core.db import connection

ROOT = Path(__file__).resolve().parents[1]
def migrar_v3(cur):
    cur.execute('SELECT 1 FROM versoes_schema WHERE versao=3')
    if cur.fetchone():return
    original=json.loads((ROOT/'dados/extrato.json').read_text(encoding='utf-8'))
    referencias={x['referencia']:x['documento_id'] for x in json.loads((ROOT/'dados/interno.json').read_text(encoding='utf-8'))}
    cur.execute('SELECT extrato FROM conciliacao WHERE id=1');atual=cur.fetchone()
    if atual and atual[0]==original:
        novo=[dict(x,referencia=referencias.get(x['referencia'],x['referencia'])) for x in original]
        cur.execute('UPDATE conciliacao SET extrato=%s WHERE id=1',(Json(novo),))
    cur.execute("UPDATE dre_grupos SET nome='EBITDA' WHERE codigo='ebitda' AND nome='Resultado antes da depreciação e financeiro'")
    cur.execute('INSERT INTO versoes_schema(versao) VALUES(3)')

def migrar_v2(cur):
    cur.execute('SELECT 1 FROM versoes_schema WHERE versao=2')
    if cur.fetchone():return
    grupos=[('receita_bruta','Receita bruta',10,'detalhe'),('deducoes','Deduções da receita',20,'detalhe'),('receita_liquida','Receita líquida',30,'subtotal'),('custos_servicos','Custos dos serviços',40,'detalhe'),('lucro_bruto','Lucro bruto',50,'subtotal'),('pessoal','Despesas com pessoal',60,'detalhe'),('estrutura','Despesas de estrutura',70,'detalhe'),('ebitda','Resultado antes da depreciação e financeiro',80,'subtotal'),('depreciacao','Depreciação',90,'detalhe'),('ebit','Resultado operacional',100,'subtotal'),('financeiro','Resultado financeiro',110,'detalhe'),('resultado_antes_tributos','Resultado antes dos tributos',120,'subtotal'),('tributos_resultado','Tributos sobre o resultado',130,'detalhe'),('resultado_liquido','Resultado líquido',140,'subtotal')]
    for g in grupos:cur.execute('INSERT INTO dre_grupos VALUES(%s,%s,%s,%s) ON CONFLICT DO NOTHING',g)
    cur.execute("INSERT INTO dre_vinculos SELECT c.conta_id,'',g.codigo FROM contas c JOIN dre_grupos g ON g.codigo=c.linha_dre WHERE c.grupo='resultado' AND g.tipo='detalhe' ON CONFLICT DO NOTHING")
    cur.execute("INSERT INTO centros SELECT DISTINCT centro_id,centro_id FROM lancamentos WHERE centro_id<>'' ON CONFLICT DO NOTHING")
    cur.execute("UPDATE contas SET classe_bp=CASE WHEN componente IN ('imobilizado','redutora_imobilizado') THEN 'nao_circulante' WHEN grupo IN ('pl','resultado') THEN grupo ELSE 'circulante' END,natureza=CASE WHEN grupo='ativo' THEN 'devedora' ELSE 'credora' END")
    cur.execute('INSERT INTO versoes_schema(versao) VALUES(2)')

def semear_demonstracao(cur):
    """Semente legada, somente para testes que a chamarem explicitamente."""
    load=lambda f: json.loads((ROOT/'dados'/f).read_text(encoding='utf-8'))
    for x in load('contas.json'):
        cur.execute('INSERT INTO contas(conta_id,descricao,grupo,componente,linha_dre,analitica) VALUES (%s,%s,%s,%s,%s,%s)', tuple(x[k] for k in ['conta_id','descricao','grupo','componente','linha_dre','analitica']))
    campos=['linha_id','documento_id','empresa_id','data','conta_id','debito_centavos','credito_centavos','tipo','historico','origem_id','centro_id','atividade_caixa','rubrica_caixa']
    for x in load('lancamentos.json'):
        cur.execute('INSERT INTO lancamentos VALUES ('+','.join(['%s']*len(campos))+')', tuple(x.get(k) if x.get(k) is not None else '' for k in campos))
    for x in load('orcamento.json'):
        cur.execute('INSERT INTO orcamento VALUES (%s,%s,%s)',(x['competencia'],x['conta_id'],x['valor_dc_centavos']))
    cur.execute('INSERT INTO conciliacao VALUES (1,%s)',(Json(load('extrato.json')),))


def ler_dotenv():
    valores = {}
    for caminho in (ROOT / '.env', ROOT.parent / '.env'):
        if not caminho.is_file():
            continue
        for linha in caminho.read_text(encoding='utf-8').splitlines():
            linha = linha.strip()
            if not linha or linha.startswith('#') or '=' not in linha:
                continue
            chave, valor = linha.split('=', 1)
            valores[chave.strip()] = valor.strip().strip('"').strip("'")
    return valores


def credenciais_admin():
    arquivo = ler_dotenv()
    email = (os.environ.get('ADMINUSER') or os.environ.get('ADMIN_USER') or arquivo.get('ADMINUSER') or arquivo.get('ADMIN_USER') or '').strip().lower()
    senha = os.environ.get('ADMINPASSWORD') or os.environ.get('ADMIN_PASSWORD') or arquivo.get('ADMINPASSWORD') or arquivo.get('ADMIN_PASSWORD') or ''
    return email, senha


def sincronizar_admin(cur):
    email, senha = credenciais_admin()
    if not email or not senha:
        raise RuntimeError('Defina ADMINUSER e ADMINPASSWORD para criar o único acesso.')
    if len(senha.encode('utf-8')) > 72:
        raise RuntimeError('A senha do admin excede o limite de 72 bytes.')
    cur.execute('DELETE FROM preferencias_ui WHERE email <> %s', (email,))
    cur.execute('DELETE FROM usuarios WHERE email <> %s', (email,))
    cur.execute(
        'INSERT INTO usuarios(email, senha_hash) VALUES (%s, %s) ON CONFLICT (email) DO UPDATE SET senha_hash = EXCLUDED.senha_hash',
        (email, generate_password_hash(senha).decode()),
    )
    print('Acesso restrito ao administrador.')


def main():
    with connection() as conn, conn.cursor() as cur:
        cur.execute('SELECT pg_advisory_xact_lock(20260910)')
        cur.execute((ROOT/'scripts/schema.sql').read_text(encoding='utf-8'))
        sincronizar_admin(cur)
        for versao in (1,2,3,4,5,6):
            cur.execute('INSERT INTO versoes_schema(versao) VALUES(%s) ON CONFLICT DO NOTHING',(versao,))
        print('Banco preparado. Acesso disponível; dados existentes preservados.')
        return

if __name__=='__main__': main()
