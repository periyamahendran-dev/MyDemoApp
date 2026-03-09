try {
    List<String> currencies = CurrencyConverterController.getSupportedCurrencies();
    System.debug('SUCCESS: Got ' + currencies.size() + ' currencies');
    for (Integer i = 0; i < Math.min(5, currencies.size()); i++) {
        System.debug('Currency: ' + currencies[i]);
    }
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('TYPE: ' + e.getTypeName());
}
