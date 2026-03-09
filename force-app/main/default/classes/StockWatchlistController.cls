public with sharing class StockWatchlistController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableProviders() {
        return StockQuoteProviderFactory.getAvailableProviders();
    }

    @AuraEnabled
    public static Map<String, String> getSelectedProvider() {
        try {
            Stock_Provider_Preference__c pref = Stock_Provider_Preference__c.getInstance(UserInfo.getUserId());
            String provider = pref != null && String.isNotBlank(pref.Selected_Provider__c)
                ? pref.Selected_Provider__c
                : StockQuoteProviderFactory.getDefaultProvider();
            Datetime lastFetch = pref != null ? pref.Last_Fetch_Timestamp__c : null;

            Map<String, String> result = new Map<String, String>();
            result.put('provider', provider);
            result.put('lastFetchTimestamp', lastFetch != null ? lastFetch.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '');
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void setSelectedProvider(String providerName) {
        try {
            if (String.isBlank(providerName)) {
                throw new AuraHandledException('Provider name is required');
            }
            Stock_Provider_Preference__c pref = Stock_Provider_Preference__c.getInstance(UserInfo.getUserId());
            if (pref == null || pref.Id == null) {
                pref = new Stock_Provider_Preference__c(
                    SetupOwnerId = UserInfo.getUserId(),
                    Selected_Provider__c = providerName
                );
                insert pref;
            } else {
                pref.Selected_Provider__c = providerName;
                update pref;
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<StockService.StockSearchResult> searchStocks(String keywords, String providerName) {
        try {
            StockQuoteProvider provider = StockQuoteProviderFactory.getProvider(providerName);
            return provider.searchStocks(keywords);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static StockService.StockQuote getStockQuote(String symbol, String providerName) {
        try {
            StockQuoteProvider provider = StockQuoteProviderFactory.getProvider(providerName);
            List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ symbol });
            if (quotes.isEmpty()) {
                throw new StockService.StockServiceException('No quote data returned for symbol: ' + symbol);
            }
            return quotes[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> refreshAllQuotes(String symbolsJson, String providerName) {
        try {
            List<String> symbols = (List<String>) JSON.deserialize(symbolsJson, List<String>.class);
            if (symbols == null || symbols.isEmpty()) {
                throw new StockService.StockServiceException('No stocks found to update.');
            }

            StockQuoteProvider provider = StockQuoteProviderFactory.getProvider(providerName);
            List<StockService.StockQuote> quotes = provider.getQuotes(symbols);

            Datetime now = Datetime.now();
            updateLastFetchTimestamp(now);

            Map<String, Object> result = new Map<String, Object>();
            result.put('quotes', quotes);
            result.put('lastFetchTimestamp', now.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
            result.put('providerName', provider.getProviderName());
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void updateLastFetchTimestamp(Datetime fetchTime) {
        try {
            Stock_Provider_Preference__c pref = Stock_Provider_Preference__c.getInstance(UserInfo.getUserId());
            if (pref != null && pref.Id != null) {
                pref.Last_Fetch_Timestamp__c = fetchTime;
                update pref;
            }
        } catch (Exception e) {
            // Non-critical: timestamp update failure should not block the main operation
        }
    }

    @AuraEnabled
    public static Id saveWatchlist(String watchlistName, String itemsJson, Id watchlistId) {
        try {
            if (String.isBlank(watchlistName)) {
                throw new AuraHandledException('Watchlist name is required');
            }

            Stock_Watchlist__c record;
            if (watchlistId != null) {
                record = [
                    SELECT Id FROM Stock_Watchlist__c
                    WHERE Id = :watchlistId AND User__c = :UserInfo.getUserId()
                    LIMIT 1
                ];
                record.Watchlist_Name__c = watchlistName;
                record.Items_JSON__c = itemsJson;
                update record;
            } else {
                record = new Stock_Watchlist__c(
                    Watchlist_Name__c = watchlistName,
                    Items_JSON__c = itemsJson,
                    User__c = UserInfo.getUserId()
                );
                insert record;
            }
            return record.Id;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Stock_Watchlist__c> getUserWatchlists() {
        try {
            return [
                SELECT Id, Watchlist_Name__c, CreatedDate, LastModifiedDate
                FROM Stock_Watchlist__c
                WHERE User__c = :UserInfo.getUserId()
                ORDER BY LastModifiedDate DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadWatchlist(Id watchlistId) {
        try {
            Stock_Watchlist__c record = [
                SELECT Id, Watchlist_Name__c, Items_JSON__c
                FROM Stock_Watchlist__c
                WHERE Id = :watchlistId AND User__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            return JSON.serialize(record);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteWatchlist(Id watchlistId) {
        try {
            Stock_Watchlist__c record = [
                SELECT Id FROM Stock_Watchlist__c
                WHERE Id = :watchlistId AND User__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            delete record;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
