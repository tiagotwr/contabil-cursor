CREATE TABLE IF NOT EXISTS usuarios (
 email text PRIMARY KEY, senha_hash text NOT NULL
);
CREATE TABLE IF NOT EXISTS contas (
 conta_id text PRIMARY KEY, descricao text NOT NULL, grupo text NOT NULL,
 componente text, linha_dre text, analitica boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS lancamentos (
 linha_id text PRIMARY KEY, documento_id text NOT NULL, empresa_id text NOT NULL,
 data date NOT NULL, conta_id text NOT NULL REFERENCES contas,
 debito_centavos bigint NOT NULL CHECK(debito_centavos>=0),
 credito_centavos bigint NOT NULL CHECK(credito_centavos>=0),
 tipo text NOT NULL, historico text NOT NULL, origem_id text NOT NULL,
 centro_id text NOT NULL DEFAULT '', atividade_caixa text NOT NULL DEFAULT '', rubrica_caixa text NOT NULL DEFAULT '',
 CHECK(debito_centavos=0 OR credito_centavos=0)
);
CREATE INDEX IF NOT EXISTS lancamentos_data ON lancamentos(data,conta_id);
CREATE TABLE IF NOT EXISTS orcamento (
 competencia text NOT NULL, conta_id text NOT NULL REFERENCES contas,
 valor_dc_centavos bigint NOT NULL, PRIMARY KEY(competencia,conta_id)
);
CREATE TABLE IF NOT EXISTS reclassificacoes (
 competencia text NOT NULL, conta_id text NOT NULL REFERENCES contas,
 destino text NOT NULL CHECK(destino IN ('estrutura','custos_servicos')),
 PRIMARY KEY(competencia,conta_id)
);
CREATE TABLE IF NOT EXISTS auditoria (
 id bigserial PRIMARY KEY, data timestamptz NOT NULL DEFAULT now(),
 acao text NOT NULL, antes jsonb NOT NULL, depois jsonb NOT NULL
);
CREATE TABLE IF NOT EXISTS conciliacao (
 id integer PRIMARY KEY CHECK(id=1), extrato jsonb NOT NULL
);
CREATE TABLE IF NOT EXISTS login_tentativas (
 ip text PRIMARY KEY, quantidade integer NOT NULL DEFAULT 0, atualizado timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS versoes_schema (versao integer PRIMARY KEY, aplicada timestamptz NOT NULL DEFAULT now());
ALTER TABLE contas ADD COLUMN IF NOT EXISTS conta_pai_id text NOT NULL DEFAULT '';
ALTER TABLE contas ADD COLUMN IF NOT EXISTS ordem integer NOT NULL DEFAULT 100;
ALTER TABLE contas ADD COLUMN IF NOT EXISTS nivel integer NOT NULL DEFAULT 1;
ALTER TABLE contas ADD COLUMN IF NOT EXISTS natureza text NOT NULL DEFAULT '';
ALTER TABLE contas ADD COLUMN IF NOT EXISTS classe_bp text NOT NULL DEFAULT 'pendente';
CREATE TABLE IF NOT EXISTS centros (centro_id text PRIMARY KEY,descricao text NOT NULL);
CREATE TABLE IF NOT EXISTS regras_centros (
 id bigserial PRIMARY KEY,conta_id text NOT NULL DEFAULT '',
 centro_origem text NOT NULL,centro_destino text NOT NULL REFERENCES centros,
 inicio date NOT NULL,fim date NOT NULL,prioridade integer UNIQUE NOT NULL,
 justificativa text NOT NULL,CHECK(inicio<=fim)
);
CREATE TABLE IF NOT EXISTS dre_grupos (
 codigo text PRIMARY KEY,nome text NOT NULL,ordem integer UNIQUE NOT NULL,
 tipo text NOT NULL CHECK(tipo IN ('detalhe','subtotal'))
);
CREATE TABLE IF NOT EXISTS dre_vinculos (
 conta_id text NOT NULL REFERENCES contas,centro_id text NOT NULL DEFAULT '',
 grupo_codigo text NOT NULL REFERENCES dre_grupos,PRIMARY KEY(conta_id,centro_id)
);
CREATE TABLE IF NOT EXISTS dre_contas_config (
 conta_id text PRIMARY KEY REFERENCES contas ON DELETE CASCADE,
 modo text NOT NULL CHECK(modo IN ('linha','centro')),
 grupo_codigo text REFERENCES dre_grupos,
 CHECK(modo='linha' OR grupo_codigo IS NULL)
);
CREATE TABLE IF NOT EXISTS dre_centros_config (
 centro_id text PRIMARY KEY REFERENCES centros ON DELETE CASCADE,
 grupo_codigo text REFERENCES dre_grupos
);
CREATE TABLE IF NOT EXISTS importacoes_previa (
 token text PRIMARY KEY,criada timestamptz NOT NULL DEFAULT now(),
 arquivo text NOT NULL,conteudo jsonb NOT NULL
);
CREATE TABLE IF NOT EXISTS bases_arquivadas (
 id bigserial PRIMARY KEY,criada timestamptz NOT NULL DEFAULT now(),
 motivo text NOT NULL,conteudo jsonb NOT NULL
);
CREATE TABLE IF NOT EXISTS preferencias_ui (
 email text NOT NULL REFERENCES usuarios(email),chave text NOT NULL,
 valor jsonb NOT NULL DEFAULT '{}'::jsonb,PRIMARY KEY(email,chave)
);
CREATE TABLE IF NOT EXISTS conciliacoes_titulos (
 id integer PRIMARY KEY CHECK(id=1), arquivos jsonb NOT NULL,
 resultado jsonb NOT NULL, atualizado timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS configuracoes_ia (
 id integer PRIMARY KEY CHECK(id=1),chave text NOT NULL,modelo text NOT NULL,
 atualizado timestamptz NOT NULL DEFAULT clock_timestamp()
);
