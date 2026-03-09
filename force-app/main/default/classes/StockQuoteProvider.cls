public interface StockQuoteProvider {
    List<StockService.StockQuote> getQuotes(List<String> symbols);
    List<StockService.StockSearchResult> searchStocks(String keywords);
    String getProviderName();
}
