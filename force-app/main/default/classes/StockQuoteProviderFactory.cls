public with sharing class StockQuoteProviderFactory {

    public static final String ALPHA_VANTAGE = 'Alpha_Vantage';
    public static final String FINNHUB = 'Finnhub';
    public static final String MASSIVE = 'Massive';

    private static final Map<String, String> PROVIDER_LABELS = new Map<String, String>{
        ALPHA_VANTAGE => 'Alpha Vantage',
        FINNHUB => 'Finnhub',
        MASSIVE => 'Massive'
    };

    public static StockQuoteProvider getProvider(String providerName) {
        if (String.isBlank(providerName)) {
            providerName = ALPHA_VANTAGE;
        }
        switch on providerName {
            when 'Finnhub' {
                return new FinnhubProvider();
            }
            when 'Massive' {
                return new MassiveProvider();
            }
            when else {
                return new AlphaVantageProvider();
            }
        }
    }

    public static List<Map<String, String>> getAvailableProviders() {
        List<Map<String, String>> providers = new List<Map<String, String>>();
        for (String key : PROVIDER_LABELS.keySet()) {
            providers.add(new Map<String, String>{
                'value' => key,
                'label' => PROVIDER_LABELS.get(key)
            });
        }
        return providers;
    }

    public static String getDefaultProvider() {
        return ALPHA_VANTAGE;
    }
}
