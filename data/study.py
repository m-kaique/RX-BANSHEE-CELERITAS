import numpy as np

# Parâmetros
ema_periods = [9, 20, 50]
rsi_period = 14
macd_fast = 12
macd_slow = 26
macd_signal = 9
obv_sma_period = 14
slope_window = 3
point = 1.0 # WIN = 1.0

# EMA
for period in ema_periods:
    df[f'EMA_{period}'] = df['<CLOSE>'].ewm(span=period, adjust=False).mean()

# RSI
delta = df['<CLOSE>'].diff()
gain = (delta.where(delta > 0, 0)).rolling(window=rsi_period).mean()
loss = (-delta.where(delta < 0, 0)).rolling(window=rsi_period).mean()
rs = gain / loss
df['RSI_14'] = 100 - (100 / (1 + rs))

# MACD
ema_fast = df['<CLOSE>'].ewm(span=macd_fast, adjust=False).mean()
ema_slow = df['<CLOSE>'].ewm(span=macd_slow, adjust=False).mean()
df['MACD_main'] = ema_fast - ema_slow
df['MACD_signal'] = df['MACD_main'].ewm(span=macd_signal, adjust=False).mean()

# OBV
obv = [0]
close = df['<CLOSE>']
vol = df['<VOL>']
for i in range(1, len(df)):
    if close[i] > close[i - 1]:
        obv.append(obv[-1] + vol[i])
    elif close[i] < close[i - 1]:
        obv.append(obv[-1] - vol[i])
    else:
        obv.append(obv[-1])
df['OBV'] = obv
df['OBV_SMA_14'] = df['OBV'].rolling(window=obv_sma_period).mean()

# Slope das EMAs (usando regressão linear simples em 3 candles)
def calc_slope(series, window=slope_window):
    slope = [np.nan] * (window - 1)
    for i in range(window - 1, len(series)):
        y = series[i - window + 1: i + 1]
        x = np.arange(window)
        # Coef angular da reta (em pontos/candle)
        m = np.polyfit(x, y, 1)[0]
        slope.append(m)
    return slope

for period in ema_periods:
    df[f'SLOPE_EMA_{period}_3'] = calc_slope(df[f'EMA_{period}'], window=slope_window)

# Diff EMAs (em pontos)
df['diff9_20'] = np.abs(df['EMA_9'] - df['EMA_20']) / point
df['diff20_50'] = np.abs(df['EMA_20'] - df['EMA_50']) / point

# Seleção final das colunas para exibir
colunas = [
    '<DATE>', '<TIME>', '<CLOSE>',
    'EMA_9', 'EMA_20', 'EMA_50',
    'RSI_14',
    'MACD_main', 'MACD_signal',
    'OBV', 'OBV_SMA_14',
    'SLOPE_EMA_9_3', 'SLOPE_EMA_20_3', 'SLOPE_EMA_50_3',
    'diff9_20', 'diff20_50'
]

resultado = df[colunas].copy()
resultado.head(10)
