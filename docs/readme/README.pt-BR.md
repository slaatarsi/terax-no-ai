# Terax

**Um terminal leve com explorador de pastas e acompanhamento do Git. Sem agentes de IA integrados.**

Esta versão é um fork modificado de [crynta/terax-ai](https://github.com/crynta/terax-ai), mantido separadamente em [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai). O projeto original é de Crynta e dos colaboradores upstream.

## Recursos

- Terminal nativo com abas, painéis divididos, busca e integração com o shell.
- Explorador de pastas com busca, gerenciamento de arquivos e atualizações em tempo real.
- Status do Git, diffs, preparação de alterações, commits, push e histórico gráfico.
- Editor, servidores de linguagem opcionais, prévias e temas permanecem como ferramentas complementares.

Sem chat de IA, agentes, provedores de IA, autocompletar com IA ou entrada de voz integrados. Programas CLI ainda podem ser executados manualmente. Dados antigos de IA e hooks externos não são carregados nem removidos automaticamente.

## Compilar

Requer Rust estável, Node 22+, pnpm e os [pré-requisitos do Tauri](https://tauri.app/start/prerequisites/).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Pacote de produção:
pnpm tauri build
```

**Atenção:** a configuração de atualização ainda aponta para os releases upstream. Aceitar uma atualização pode substituir este fork pela versão original. Instaladores e pacotes upstream não devem ser tratados como esta versão sem IA. Não há garantia de assinatura específica deste fork.

Consulte o [README em inglês](../../README.md) para instruções completas e limitações de distribuição. Veja também a [documentação](../README.md), o [guia de contribuição](../../CONTRIBUTING.md) e a [política de segurança](../../SECURITY.md). Relate problemas no repositório deste fork.

Licença [Apache-2.0](../../LICENSE). Créditos e avisos originais são preservados.
