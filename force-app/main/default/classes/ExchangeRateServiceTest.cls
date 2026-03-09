@isTest
private class ExchangeRateServiceTest {

    // --- ExchangeRate-API provider tests ---

    @isTest
    static void testGetExchangeRatesSuccess() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        Map<String, Decimal> rates = ExchangeRateService.getExchangeRates('USD', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
        Test.stopTest();

        System.assertNotEquals(null, rates, 'Rates should not be null');
        System.assert(rates.size() > 0, 'Rates map should not be empty');
        System.assertEquals(0.85, rates.get('EUR'), 'EUR rate should be 0.85');
        System.assertEquals(1, rates.get('USD'), 'USD rate should be 1');
        System.assertEquals(110.0, rates.get('JPY'), 'JPY rate should be 110.0');
    }

    @isTest
    static void testGetExchangeRatesDefaultProvider() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        Map<String, Decimal> rates = ExchangeRateService.getExchangeRates('USD', null);
        Test.stopTest();

        System.assertNotEquals(null, rates, 'Rates should not be null');
        System.assert(rates.size() > 0, 'Rates map should not be empty');
    }

    @isTest
    static void testGetExchangeRatesBlankCurrency() {
        Test.startTest();
        try {
            ExchangeRateService.getExchangeRates('', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assertEquals('Base currency cannot be blank', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetExchangeRatesApiError() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock(500, 'Server Error'));

        Test.startTest();
        try {
            ExchangeRateService.getExchangeRates('USD', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assert(e.getMessage().contains('API request failed'), 'Error message should mention API failure');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetExchangeRatesErrorResult() {
        Test.setMock(
            HttpCalloutMock.class,
            new ExchangeRateCalloutMock(200, ExchangeRateCalloutMock.getErrorResponse())
        );

        Test.startTest();
        try {
            ExchangeRateService.getExchangeRates('INVALID', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assert(e.getMessage().contains('API returned error'), 'Error message should mention error result');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSupportedCurrencies() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        List<String> currencies = ExchangeRateService.getSupportedCurrencies(ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
        Test.stopTest();

        System.assertNotEquals(null, currencies, 'Currencies list should not be null');
        System.assert(currencies.size() > 0, 'Currencies list should not be empty');
        System.assert(currencies.contains('EUR'), 'Should contain EUR');
        System.assert(currencies.contains('USD'), 'Should contain USD');

        for (Integer i = 1; i < currencies.size(); i++) {
            System.assert(
                currencies[i - 1] <= currencies[i],
                'Currencies should be sorted alphabetically'
            );
        }
    }

    @isTest
    static void testConvertSuccess() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        ExchangeRateService.ConversionResult result = ExchangeRateService.convert(100, 'USD', 'EUR', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(100, result.originalAmount, 'Original amount should be 100');
        System.assertEquals('USD', result.fromCurrency, 'From currency should be USD');
        System.assertEquals('EUR', result.toCurrency, 'To currency should be EUR');
        System.assertEquals(0.85, result.exchangeRate, 'Exchange rate should be 0.85');
        System.assertEquals(85.00, result.convertedAmount, 'Converted amount should be 85.00');
        System.assertEquals('ExchangeRate-API', result.providerName, 'Provider should be ExchangeRate-API');
    }

    @isTest
    static void testConvertInvalidAmount() {
        Test.startTest();
        try {
            ExchangeRateService.convert(0, 'USD', 'EUR', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assert(e.getMessage().contains('greater than zero'), 'Should mention amount must be > 0');
        }
        Test.stopTest();
    }

    @isTest
    static void testConvertBlankCurrencies() {
        Test.startTest();
        try {
            ExchangeRateService.convert(100, '', 'EUR', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention currencies are required');
        }
        Test.stopTest();
    }

    @isTest
    static void testConvertUnsupportedCurrency() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        try {
            ExchangeRateService.convert(100, 'USD', 'XYZ', ExchangeRateService.PROVIDER_EXCHANGE_RATE_API);
            System.assert(false, 'Should have thrown ExchangeRateException');
        } catch (ExchangeRateService.ExchangeRateException e) {
            System.assert(e.getMessage().contains('Unsupported'), 'Should mention unsupported currency');
        }
        Test.stopTest();
    }

    // --- Frankfurter provider tests ---

    @isTest
    static void testGetExchangeRatesFromFrankfurter() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        Map<String, Decimal> rates = ExchangeRateService.getExchangeRates('USD', ExchangeRateService.PROVIDER_FRANKFURTER);
        Test.stopTest();

        System.assertNotEquals(null, rates, 'Rates should not be null');
        System.assert(rates.size() > 0, 'Rates map should not be empty');
        System.assertEquals(0.85, rates.get('EUR'), 'EUR rate should be 0.85');
        System.assertEquals(1, rates.get('USD'), 'Base currency rate should be 1');
    }

    @isTest
    static void testConvertFromFrankfurter() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        ExchangeRateService.ConversionResult result = ExchangeRateService.convert(100, 'USD', 'EUR', ExchangeRateService.PROVIDER_FRANKFURTER);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(85.00, result.convertedAmount, 'Converted amount should be 85.00');
        System.assertEquals('Frankfurter (ECB)', result.providerName, 'Provider should be Frankfurter (ECB)');
    }

    @isTest
    static void testGetSupportedCurrenciesFromFrankfurter() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        List<String> currencies = ExchangeRateService.getSupportedCurrencies(ExchangeRateService.PROVIDER_FRANKFURTER);
        Test.stopTest();

        System.assertNotEquals(null, currencies, 'Currencies should not be null');
        System.assert(currencies.size() > 0, 'Should have at least one currency');
        System.assert(currencies.contains('USD'), 'Should contain base currency USD');
    }

    // --- Fawaz Ahmed provider tests ---

    @isTest
    static void testGetExchangeRatesFromFawazAhmed() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        Map<String, Decimal> rates = ExchangeRateService.getExchangeRates('USD', ExchangeRateService.PROVIDER_FAWAZ_AHMED);
        Test.stopTest();

        System.assertNotEquals(null, rates, 'Rates should not be null');
        System.assert(rates.size() > 0, 'Rates map should not be empty');
        System.assertEquals(0.85, rates.get('EUR'), 'EUR rate should be 0.85');
    }

    @isTest
    static void testConvertFromFawazAhmed() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        ExchangeRateService.ConversionResult result = ExchangeRateService.convert(100, 'USD', 'EUR', ExchangeRateService.PROVIDER_FAWAZ_AHMED);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(85.00, result.convertedAmount, 'Converted amount should be 85.00');
        System.assertEquals('Fawaz Ahmed', result.providerName, 'Provider should be Fawaz Ahmed');
    }

    @isTest
    static void testGetSupportedCurrenciesFromFawazAhmed() {
        Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

        Test.startTest();
        List<String> currencies = ExchangeRateService.getSupportedCurrencies(ExchangeRateService.PROVIDER_FAWAZ_AHMED);
        Test.stopTest();

        System.assertNotEquals(null, currencies, 'Currencies should not be null');
        System.assert(currencies.size() > 0, 'Should have at least one currency');
    }
}
