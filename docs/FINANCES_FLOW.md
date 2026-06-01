# Grupli Finances Flow

## Objetivo

Finanzas debe funcionar como un Tricount sencillo:

1. Un miembro paga algo.
2. Se eligen participantes.
3. Se reparte igual o manual.
4. Grupli calcula el saldo neto de cada usuario.
5. Grupli simplifica deudas: muestra quién debe pagar a quién.
6. Se pueden registrar pagos/liquidaciones.
7. Los pagos marcados como pagados reducen el saldo pendiente.

## Estados

### Expenses

- `pending`: cuenta en balances.
- `paid`: queda registrado pero no cuenta como deuda pendiente.
- `cancelled`: queda fuera del balance.

### Settlements

- `pending`: pago registrado pero aún no confirmado.
- `paid`: reduce balances.
- `cancelled`: no afecta balances.

## Reglas

- El pagador no siempre queda exento: si participa también se le resta su parte.
- El reparto manual debe sumar igual que el total.
- Los balances visibles se calculan de forma neta para evitar listas largas de microdeudas.
- El usuario debe entender cada gasto con una frase simple:
  - "Pedro pagó 30 €. Se reparte entre 3. Cada uno debe 10 €."

## Próxima fase

- Liquidaciones más avanzadas.
- Edición de gastos.
- Historial detallado por usuario.
- Exportación CSV futura.
