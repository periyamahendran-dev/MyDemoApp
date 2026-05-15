public with sharing class CurrencyConverterController {
  @AuraEnabled
  public static List<String> getSupportedCurrencies(String provider) {
    try {
      return ExchangeRateService.getSupportedCurrencies(provider);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static ExchangeRateService.ConversionResult convertCurrency(
    String fromCurrency,
    String toCurrency,
    Decimal amount,
    String provider,
    String rateDate
  ) {
    try {
      ExchangeRateService.ConversionResult result = ExchangeRateService.convert(
        amount,
        fromCurrency,
        toCurrency,
        provider,
        rateDate
      );

      saveConversionHistory(result, provider, rateDate);

      return result;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Currency_Conversion__c> getConversionHistory(
    Integer recordLimit
  ) {
    try {
      Integer queryLimit = (recordLimit != null &&
        recordLimit > 0 &&
        recordLimit <= 100)
        ? recordLimit
        : 10;
      return [
        SELECT
          Id,
          Name,
          From_Currency__c,
          To_Currency__c,
          Amount__c,
          Converted_Amount__c,
          Exchange_Rate__c,
          Conversion_Date__c,
          Rate_Provider__c
        FROM Currency_Conversion__c
        WHERE User__c = :UserInfo.getUserId()
        ORDER BY Conversion_Date__c DESC
        LIMIT :queryLimit
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Decimal getExchangeRate(
    String fromCurrency,
    String toCurrency,
    String provider,
    String rateDate
  ) {
    try {
      Map<String, Decimal> rates = ExchangeRateService.getExchangeRates(
        fromCurrency,
        provider,
        rateDate
      );
      Decimal rate = rates.get(toCurrency.toUpperCase());
      if (rate == null) {
        throw new ExchangeRateService.ExchangeRateException(
          'Unsupported currency pair'
        );
      }
      return rate;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteConversionHistory(Id recordId) {
    try {
      Currency_Conversion__c record = [
        SELECT Id
        FROM Currency_Conversion__c
        WHERE Id = :recordId AND User__c = :UserInfo.getUserId()
        LIMIT 1
      ];
      delete record;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static void saveConversionHistory(
    ExchangeRateService.ConversionResult result,
    String provider,
    String rateDate
  ) {
    Currency_Conversion__c record = new Currency_Conversion__c(
      From_Currency__c = result.fromCurrency,
      To_Currency__c = result.toCurrency,
      Amount__c = result.originalAmount,
      Converted_Amount__c = result.convertedAmount,
      Exchange_Rate__c = result.exchangeRate,
      Conversion_Date__c = DateTime.now(),
      User__c = UserInfo.getUserId(),
      Rate_Provider__c = result.providerName
    );
    if (String.isNotBlank(rateDate)) {
      record.Rate_Date__c = Date.valueOf(rateDate);
    }
    insert record;
  }
}
