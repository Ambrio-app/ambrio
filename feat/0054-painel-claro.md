# 0054 — Painel da tela inicial mais claro

**Data:** 2026-11-24 · **Status:** ✅ concluído

## O que mudou

- **Legenda da barra** ([`month_panel_card.dart`](../lib/features/entries/presentation/month_panel_card.dart)): sob a barra de gasto, "Gastou R$ X" na ponta esquerda e "Entrou R$ Y" na direita (a barra inteira é o que entrou).
  Substitui a linha "Entrou … · Gastou …". Com o olhinho fechado ficam só as palavras. Continua uma barra só (a barra "Entrou" sempre em 100% não existe).
- **Cartões com o valor em aberto** ([`month_panel.dart`](../lib/features/entries/domain/month_panel.dart)): o painel lista até **dois** cartões com algo em aberto e dia de vencimento, do que vence primeiro ao último
  ("Nubank vence em 3 dias" e, à direita, o em aberto), sob o título "Cartões, em aberto". O valor respeita o olhinho. `nextDue` continua existindo (o primeiro da lista).
- **Título da lista** ([`month_screen.dart`](../lib/features/entries/presentation/month_screen.dart)): "Lançamentos de novembro de 2026" antes dos lançamentos, só quando há.
- **Leitor de tela:** a fala do painel inclui cada cartão ("Cartão Nubank vence em 3 dias, em aberto, valor oculto") e continua sem ler reais com o olhinho fechado.

## Por quê

Brainstorm 008 (veredito do autor: "A melhorada agora"). No teste dos cinco segundos, cinco personas leram bem os valores, mas a barra não dizia o que cada ponta era, o em aberto do cartão sumia e a lista não
tinha título (duas pessoas ficaram em dúvida de onde tocar). Tela Início com barra inferior fica para a 1.1 (junto com parcelas e assinaturas); abas por tipo e IA de conversa ficam de fora por ora.

## O que **não** mudou, de propósito

- **O olhinho continua só com o ícone.** Testei com "Mostrar/Ocultar" ao lado (e em chip), em claro e escuro, com texto normal e 200%: é mais um elemento num canto já apertado e, com texto grande, encosta no
  "Em conta". Por decisão do autor ("se ficar mais uma informação na tela, não aplique"), o ícone fica como está, com o tooltip e o rótulo para o leitor de tela.

## Como verificar

`flutter test test/features/entries/month_panel_test.dart test/features/entries/month_filters_test.dart`. As imagens das propostas estão em `_local` (privado); `tool/audit/prototipos_inicio_test.dart` as reproduz.
