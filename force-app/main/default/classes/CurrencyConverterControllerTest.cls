@isTest
private class CurrencyConverterControllerTest {
  @isTest
  static void testGetSupportedCurrencies() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    List<String> currencies = CurrencyConverterController.getSupportedCurrencies(
      ExchangeRateService.PROVIDER_EXCHANGE_RATE_API
    );
    Test.stopTest();

    System.assertNotEquals(null, currencies, 'Currencies should not be null');
    System.assert(currencies.size() > 0, 'Should return at least one currency');
  }

  @isTest
  static void testGetSupportedCurrenciesFrankfurter() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    List<String> currencies = CurrencyConverterController.getSupportedCurrencies(
      ExchangeRateService.PROVIDER_FRANKFURTER
    );
    Test.stopTest();

    System.assertNotEquals(null, currencies, 'Currencies should not be null');
    System.assert(currencies.size() > 0, 'Should return at least one currency');
  }

  @isTest
  static void testConvertCurrency() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    ExchangeRateService.ConversionResult result = CurrencyConverterController.convertCurrency(
      'USD',
      'EUR',
      100,
      ExchangeRateService.PROVIDER_EXCHANGE_RATE_API
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      85.00,
      result.convertedAmount,
      'Converted amount should be 85.00'
    );
    System.assertEquals(0.85, result.exchangeRate, 'Rate should be 0.85');
    System.assertEquals(
      'ExchangeRate-API',
      result.providerName,
      'Provider name should match'
    );

    List<Currency_Conversion__c> history = [
      SELECT
        Id,
        From_Currency__c,
        To_Currency__c,
        Amount__c,
        Converted_Amount__c,
        Exchange_Rate__c,
        User__c,
        Rate_Provider__c
      FROM Currency_Conversion__c
    ];
    System.assertEquals(
      1,
      history.size(),
      'Should have created one history record'
    );
    System.assertEquals('USD', history[0].From_Currency__c);
    System.assertEquals('EUR', history[0].To_Currency__c);
    System.assertEquals(100, history[0].Amount__c);
    System.assertEquals(85.00, history[0].Converted_Amount__c);
    System.assertEquals(0.85, history[0].Exchange_Rate__c);
    System.assertEquals(UserInfo.getUserId(), history[0].User__c);
    System.assertEquals('ExchangeRate-API', history[0].Rate_Provider__c);
  }

  @isTest
  static void testConvertCurrencyFrankfurter() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    ExchangeRateService.ConversionResult result = CurrencyConverterController.convertCurrency(
      'USD',
      'EUR',
      100,
      ExchangeRateService.PROVIDER_FRANKFURTER
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      85.00,
      result.convertedAmount,
      'Converted amount should be 85.00'
    );
    System.assertEquals(
      'Frankfurter (ECB)',
      result.providerName,
      'Provider name should match'
    );

    List<Currency_Conversion__c> history = [
      SELECT Rate_Provider__c
      FROM Currency_Conversion__c
    ];
    System.assertEquals('Frankfurter (ECB)', history[0].Rate_Provider__c);
  }

  @isTest
  static void testConvertCurrencyFawazAhmed() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    ExchangeRateService.ConversionResult result = CurrencyConverterController.convertCurrency(
      'USD',
      'EUR',
      100,
      ExchangeRateService.PROVIDER_FAWAZ_AHMED
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      85.00,
      result.convertedAmount,
      'Converted amount should be 85.00'
    );
    System.assertEquals(
      'Fawaz Ahmed',
      result.providerName,
      'Provider name should match'
    );

    List<Currency_Conversion__c> history = [
      SELECT Rate_Provider__c
      FROM Currency_Conversion__c
    ];
    System.assertEquals('Fawaz Ahmed', history[0].Rate_Provider__c);
  }

  @isTest
  static void testGetExchangeRate() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    Decimal rate = CurrencyConverterController.getExchangeRate(
      'USD',
      'EUR',
      ExchangeRateService.PROVIDER_EXCHANGE_RATE_API
    );
    Test.stopTest();

    System.assertNotEquals(null, rate, 'Rate should not be null');
    System.assertEquals(0.85, rate, 'EUR rate should be 0.85');
  }

  @isTest
  static void testGetExchangeRateInvalidPair() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    try {
      CurrencyConverterController.getExchangeRate(
        'USD',
        'XYZ',
        ExchangeRateService.PROVIDER_EXCHANGE_RATE_API
      );
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        null,
        e.getMessage(),
        'Error message should not be null'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testConvertCurrencyError() {
    Test.setMock(
      HttpCalloutMock.class,
      new ExchangeRateCalloutMock(500, 'Server Error')
    );

    Test.startTest();
    try {
      CurrencyConverterController.convertCurrency(
        'USD',
        'EUR',
        100,
        ExchangeRateService.PROVIDER_EXCHANGE_RATE_API
      );
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        null,
        e.getMessage(),
        'Error message should not be null'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testGetConversionHistory() {
    List<Currency_Conversion__c> records = new List<Currency_Conversion__c>();
    for (Integer i = 0; i < 15; i++) {
      records.add(
        new Currency_Conversion__c(
          From_Currency__c = 'USD',
          To_Currency__c = 'EUR',
          Amount__c = 100 + i,
          Converted_Amount__c = 85 + i,
          Exchange_Rate__c = 0.85,
          Conversion_Date__c = DateTime.now().addDays(-i),
          User__c = UserInfo.getUserId(),
          Rate_Provider__c = 'ExchangeRate-API'
        )
      );
    }
    insert records;

    Test.startTest();
    List<Currency_Conversion__c> history10 = CurrencyConverterController.getConversionHistory(
      10
    );
    List<Currency_Conversion__c> history25 = CurrencyConverterController.getConversionHistory(
      25
    );
    List<Currency_Conversion__c> historyDefault = CurrencyConverterController.getConversionHistory(
      null
    );
    Test.stopTest();

    System.assertEquals(
      10,
      history10.size(),
      'Should return 10 records when limit is 10'
    );
    System.assertEquals(
      15,
      history25.size(),
      'Should return all 15 records when limit is 25'
    );
    System.assertEquals(
      10,
      historyDefault.size(),
      'Should default to 10 when null'
    );
    System.assert(
      history10[0].Conversion_Date__c >= history10[1].Conversion_Date__c,
      'Records should be ordered by date descending'
    );
    System.assertNotEquals(
      null,
      history10[0].Rate_Provider__c,
      'Rate provider should be populated'
    );
  }

  @isTest
  static void testGetConversionHistoryEmpty() {
    Test.startTest();
    List<Currency_Conversion__c> history = CurrencyConverterController.getConversionHistory(
      10
    );
    Test.stopTest();

    System.assertEquals(
      0,
      history.size(),
      'Should return empty list when no history'
    );
  }

  @isTest
  static void testDeleteConversionHistory() {
    Currency_Conversion__c record = new Currency_Conversion__c(
      From_Currency__c = 'USD',
      To_Currency__c = 'EUR',
      Amount__c = 100,
      Converted_Amount__c = 85,
      Exchange_Rate__c = 0.85,
      Conversion_Date__c = DateTime.now(),
      User__c = UserInfo.getUserId(),
      Rate_Provider__c = 'ExchangeRate-API'
    );
    insert record;

    Test.startTest();
    CurrencyConverterController.deleteConversionHistory(record.Id);
    Test.stopTest();

    List<Currency_Conversion__c> remaining = [
      SELECT Id
      FROM Currency_Conversion__c
      WHERE Id = :record.Id
    ];
    System.assertEquals(0, remaining.size(), 'Record should be deleted');
  }

  @isTest
  static void testDeleteConversionHistoryInvalidId() {
    Test.startTest();
    try {
      CurrencyConverterController.deleteConversionHistory('a00000000000000AAA');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        null,
        e.getMessage(),
        'Error message should not be null'
      );
    }
    Test.stopTest();
  }

  // --- Historical rate tests ---

  @isTest
  static void testConvertCurrencyWithRateDate() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    ExchangeRateService.ConversionResult result = CurrencyConverterController.convertCurrency(
      'USD',
      'EUR',
      100,
      ExchangeRateService.PROVIDER_FRANKFURTER,
      '2026-05-14'
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      85.00,
      result.convertedAmount,
      'Converted amount should be 85.00'
    );
    System.assertEquals(
      '2026-05-14',
      result.rateDate,
      'Rate date should be preserved'
    );

    List<Currency_Conversion__c> history = [
      SELECT Rate_Date__c, Rate_Provider__c
      FROM Currency_Conversion__c
    ];
    System.assertEquals(
      1,
      history.size(),
      'Should have created one history record'
    );
    System.assertEquals(
      Date.valueOf('2026-05-14'),
      history[0].Rate_Date__c,
      'Rate date should be stored'
    );
    System.assertEquals('Frankfurter (ECB)', history[0].Rate_Provider__c);
  }

  @isTest
  static void testGetExchangeRateWithRateDate() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    Decimal rate = CurrencyConverterController.getExchangeRate(
      'USD',
      'EUR',
      ExchangeRateService.PROVIDER_FRANKFURTER,
      '2026-05-14'
    );
    Test.stopTest();

    System.assertNotEquals(null, rate, 'Rate should not be null');
    System.assertEquals(0.85, rate, 'EUR rate should be 0.85');
  }

  @isTest
  static void testConvertCurrencyWithRateDateUnsupportedProvider() {
    Test.startTest();
    try {
      CurrencyConverterController.convertCurrency(
        'USD',
        'EUR',
        100,
        ExchangeRateService.PROVIDER_EXCHANGE_RATE_API,
        '2026-05-14'
      );
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        null,
        e.getMessage(),
        'Error message should not be null'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testConvertCurrencyWithNullRateDate() {
    Test.setMock(HttpCalloutMock.class, new ExchangeRateCalloutMock());

    Test.startTest();
    ExchangeRateService.ConversionResult result = CurrencyConverterController.convertCurrency(
      'USD',
      'EUR',
      100,
      ExchangeRateService.PROVIDER_EXCHANGE_RATE_API,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      85.00,
      result.convertedAmount,
      'Converted amount should be 85.00'
    );

    List<Currency_Conversion__c> history = [
      SELECT Rate_Date__c
      FROM Currency_Conversion__c
    ];
    System.assertEquals(
      null,
      history[0].Rate_Date__c,
      'Rate date should be null for live rates'
    );
  }
}
