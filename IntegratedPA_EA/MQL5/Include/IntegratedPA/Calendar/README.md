# Módulo Calendar

Este módulo integra o calendário econômico nativo do MetaTrader 5 ao EA **IntegratedPA**.
Ele utiliza as funções `CalendarEventByCurrency`, `CalendarValueLast` e `CalendarValueHistory`
para filtrar eventos relevantes e controlar janelas de bloqueio de negociação.

## Funcionalidades Principais

- **LoadRange(from, to)** – carrega todos os eventos das moedas configuradas dentro do intervalo informado.
  Apenas notícias com importância moderada ou alta são consideradas. Os horários de cada evento
  são armazenados em `g_news` e utilizados para impedir entradas durante a divulgação.
- **LoadToday()** – atalho para `LoadRange()` que considera apenas a data atual.
- **Clear()** – remove todos os eventos carregados previamente.
- **IsNewsNow()** – verifica se o horário atual está dentro de alguma janela de notícia.
- **PrintUSDNewsToday()** – exemplo de uso que imprime no log os próximos eventos de USD do dia,
  exibindo horário, importância e valores econômicos (atual, previsão e anterior).

## Requisitos

- Terminal MetaTrader 5 atualizado e logado na conta MQL5.
- Permissão de acesso ao calendário econômico ativada.

## Exemplo Rápido

```mql5
NewsCalendar calendar;
calendar.SetCurrencies("USD,EUR");
calendar.Clear();
calendar.LoadToday();

if(calendar.IsNewsNow())
   Print("Aguardando o término da notícia...");

calendar.PrintUSDNewsToday();
```

Este módulo serve como base para a gestão automática de horários críticos no EA,
facilitando o uso das APIs nativas do MQL5 sem dependências externas.
