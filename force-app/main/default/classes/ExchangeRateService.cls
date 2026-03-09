public with sharing class ExchangeRateService {

    public static final String PROVIDER_EXCHANGE_RATE_API = 'EXCHANGE_RATE_API';
    public static final String PROVIDER_FRANKFURTER = 'FRANKFURTER';
    public static final String PROVIDER_FAWAZ_AHMED = 'FAWAZ_AHMED';

    private static final String ER_API_BASE_URL = 'callout:ExchangeRateAPI/v6/latest/';
    private static final String FRANKFURTER_BASE_URL = 'callout:FrankfurterAPI/latest?from=';
    private static final String FAWAZ_BASE_URL = 'callout:FawazCurrencyAPI/npm/@fawazahmed0/currency-api@latest/v1/currencies/';

    private static final Map<String, String> PROVIDER_LABELS = new Map<String, String>{
        PROVIDER_EXCHANGE_RATE_API => 'ExchangeRate-API',
        PROVIDER_FRANKFURTER => 'Frankfurter (ECB)',
        PROVIDER_FAWAZ_AHMED => 'Fawaz Ahmed'
    };

    public class ExchangeRateException extends Exception {}

    public class ConversionResult {
        @AuraEnabled public Decimal convertedAmount;
        @AuraEnabled public Decimal exchangeRate;
        @AuraEnabled public String fromCurrency;
        @AuraEnabled public String toCurrency;
        @AuraEnabled public Decimal originalAmount;
        @AuraEnabled public String providerName;

        public ConversionResult(Decimal originalAmount, String fromCurrency, String toCurrency, Decimal exchangeRate, String provider) {
            this.originalAmount = originalAmount;
            this.fromCurrency = fromCurrency;
            this.toCurrency = toCurrency;
            this.exchangeRate = exchangeRate;
            this.convertedAmount = (originalAmount * exchangeRate).setScale(2, RoundingMode.HALF_UP);
            this.providerName = PROVIDER_LABELS.containsKey(provider) ? PROVIDER_LABELS.get(provider) : provider;
        }
    }

    public static Map<String, Decimal> getExchangeRates(String baseCurrency, String provider) {
        if (String.isBlank(baseCurrency)) {
            throw new ExchangeRateException('Base currency cannot be blank');
        }
        if (String.isBlank(provider)) {
            provider = PROVIDER_EXCHANGE_RATE_API;
        }

        String endpoint = buildEndpoint(provider, baseCurrency.toUpperCase());

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(10000);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            throw new ExchangeRateException(
                'API request failed with status ' + response.getStatusCode() + ': ' + response.getStatus()
            );
        }

        return parseRatesResponse(provider, response.getBody(), baseCurrency.toUpperCase());
    }

    public static List<String> getSupportedCurrencies(String provider) {
        if (String.isBlank(provider)) {
            provider = PROVIDER_EXCHANGE_RATE_API;
        }
        Map<String, Decimal> rates = getExchangeRates('USD', provider);
        List<String> currencies = new List<String>(rates.keySet());
        currencies.sort();
        return currencies;
    }

    public static ConversionResult convert(Decimal amount, String fromCurrency, String toCurrency, String provider) {
        if (amount == null || amount <= 0) {
            throw new ExchangeRateException('Amount must be greater than zero');
        }
        if (String.isBlank(fromCurrency) || String.isBlank(toCurrency)) {
            throw new ExchangeRateException('Both source and target currencies are required');
        }
        if (String.isBlank(provider)) {
            provider = PROVIDER_EXCHANGE_RATE_API;
        }

        Map<String, Decimal> rates = getExchangeRates(fromCurrency.toUpperCase(), provider);
        Decimal targetRate = rates.get(toCurrency.toUpperCase());

        if (targetRate == null) {
            throw new ExchangeRateException('Unsupported target currency: ' + toCurrency);
        }

        return new ConversionResult(amount, fromCurrency.toUpperCase(), toCurrency.toUpperCase(), targetRate, provider);
    }

    private static String buildEndpoint(String provider, String baseCurrency) {
        if (provider == PROVIDER_FRANKFURTER) {
            return FRANKFURTER_BASE_URL + baseCurrency;
        } else if (provider == PROVIDER_FAWAZ_AHMED) {
            return FAWAZ_BASE_URL + baseCurrency.toLowerCase() + '.json';
        }
        return ER_API_BASE_URL + baseCurrency;
    }

    private static Map<String, Decimal> parseRatesResponse(String provider, String responseBody, String baseCurrency) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        if (provider == PROVIDER_FRANKFURTER) {
            return parseFrankfurterResponse(responseMap, baseCurrency);
        } else if (provider == PROVIDER_FAWAZ_AHMED) {
            return parseFawazAhmedResponse(responseMap, baseCurrency);
        }
        return parseErApiResponse(responseMap);
    }

    private static Map<String, Decimal> parseErApiResponse(Map<String, Object> responseMap) {
        String result = (String) responseMap.get('result');
        if (result != 'success') {
            throw new ExchangeRateException('API returned error result: ' + result);
        }

        Map<String, Object> ratesRaw = (Map<String, Object>) responseMap.get('rates');
        if (ratesRaw == null || ratesRaw.isEmpty()) {
            throw new ExchangeRateException('No exchange rates returned from API');
        }

        Map<String, Decimal> rates = new Map<String, Decimal>();
        for (String currencyCode : ratesRaw.keySet()) {
            rates.put(currencyCode, Decimal.valueOf(String.valueOf(ratesRaw.get(currencyCode))));
        }
        return rates;
    }

    private static Map<String, Decimal> parseFrankfurterResponse(Map<String, Object> responseMap, String baseCurrency) {
        Map<String, Object> ratesRaw = (Map<String, Object>) responseMap.get('rates');
        if (ratesRaw == null || ratesRaw.isEmpty()) {
            throw new ExchangeRateException('No exchange rates returned from Frankfurter API');
        }

        Map<String, Decimal> rates = new Map<String, Decimal>();
        rates.put(baseCurrency, 1);
        for (String currencyCode : ratesRaw.keySet()) {
            rates.put(currencyCode, Decimal.valueOf(String.valueOf(ratesRaw.get(currencyCode))));
        }
        return rates;
    }

    private static Map<String, Decimal> parseFawazAhmedResponse(Map<String, Object> responseMap, String baseCurrency) {
        Map<String, Object> ratesRaw = (Map<String, Object>) responseMap.get(baseCurrency.toLowerCase());
        if (ratesRaw == null || ratesRaw.isEmpty()) {
            throw new ExchangeRateException('No exchange rates returned from Fawaz Ahmed API');
        }

        Map<String, Decimal> rates = new Map<String, Decimal>();
        for (String currencyCode : ratesRaw.keySet()) {
            rates.put(currencyCode.toUpperCase(), Decimal.valueOf(String.valueOf(ratesRaw.get(currencyCode))));
        }
        return rates;
    }
}
