import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAvailableProviders from "@salesforce/apex/StockWatchlistController.getAvailableProviders";
import getSelectedProvider from "@salesforce/apex/StockWatchlistController.getSelectedProvider";
import setSelectedProvider from "@salesforce/apex/StockWatchlistController.setSelectedProvider";
import searchStocks from "@salesforce/apex/StockWatchlistController.searchStocks";
import getStockQuote from "@salesforce/apex/StockWatchlistController.getStockQuote";
import refreshAllQuotes from "@salesforce/apex/StockWatchlistController.refreshAllQuotes";
import saveWatchlist from "@salesforce/apex/StockWatchlistController.saveWatchlist";
import getUserWatchlists from "@salesforce/apex/StockWatchlistController.getUserWatchlists";
import loadWatchlist from "@salesforce/apex/StockWatchlistController.loadWatchlist";
import deleteWatchlist from "@salesforce/apex/StockWatchlistController.deleteWatchlist";

const EXCHANGE_OPTIONS = [
    { label: "All Exchanges", value: "ALL" },
    { label: "US (NYSE / NASDAQ)", value: "US" },
    { label: "India (BSE / NSE)", value: "INDIA" }
];

const WATCHLIST_COLUMNS = [
    { label: "Symbol", fieldName: "symbol", type: "text", initialWidth: 110 },
    { label: "Name", fieldName: "name", type: "text" },
    {
        label: "Price",
        fieldName: "price",
        type: "number",
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 },
        cellAttributes: { alignment: "right" }
    },
    { label: "Currency", fieldName: "currencyCode", type: "text", initialWidth: 90 },
    { label: "Change %", fieldName: "changePercent", type: "text", initialWidth: 100 },
    {
        label: "Day High",
        fieldName: "dayHigh",
        type: "number",
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 },
        cellAttributes: { alignment: "right" }
    },
    {
        label: "Day Low",
        fieldName: "dayLow",
        type: "number",
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 },
        cellAttributes: { alignment: "right" }
    },
    {
        label: "52W High",
        fieldName: "week52HighDisplay",
        type: "text",
        cellAttributes: { alignment: "right" },
        initialWidth: 100
    },
    {
        label: "52W Low",
        fieldName: "week52LowDisplay",
        type: "text",
        cellAttributes: { alignment: "right" },
        initialWidth: 100
    },
    {
        type: "action",
        typeAttributes: {
            rowActions: [{ label: "Remove", name: "remove" }]
        }
    }
];

const PROVIDER_LABELS = {
    Alpha_Vantage: "Alpha Vantage",
    Finnhub: "Finnhub",
    Massive: "Massive"
};

export default class StockWatchlist extends LightningElement {
    searchKeyword = "";
    selectedExchange = "ALL";
    isSearching = false;
    isLoadingQuote = false;
    isRefreshing = false;

    @track searchResults = [];
    @track watchlist = [];

    // Provider state
    selectedProvider = "Alpha_Vantage";
    @track providerOptions = [];
    lastFetchTimestamp = null;

    // Saved watchlist state
    @track savedWatchlists = [];
    currentWatchlistId = null;
    currentWatchlistName = "";
    showSaveModal = false;
    saveAsName = "";
    isSaving = false;
    isLoadingWatchlist = false;
    selectedSavedWatchlistId = "";

    exchangeOptions = EXCHANGE_OPTIONS;
    watchlistColumns = WATCHLIST_COLUMNS;

    @wire(getAvailableProviders)
    wiredProviders({ data, error }) {
        if (data) {
            this.providerOptions = data.map((p) => ({
                label: p.label,
                value: p.value
            }));
        } else if (error) {
            this.providerOptions = [{ label: "Alpha Vantage", value: "Alpha_Vantage" }];
        }
    }

    async connectedCallback() {
        await this.loadUserPreference();
        this.refreshSavedWatchlists();
    }

    async loadUserPreference() {
        try {
            const pref = await getSelectedProvider();
            if (pref && pref.provider) {
                this.selectedProvider = pref.provider;
            }
            if (pref && pref.lastFetchTimestamp) {
                this.lastFetchTimestamp = pref.lastFetchTimestamp;
            }
        } catch (error) {
            // Fall back to default
        }
    }

    get activeProviderLabel() {
        return PROVIDER_LABELS[this.selectedProvider] || this.selectedProvider;
    }

    get lastFetchDisplay() {
        if (!this.lastFetchTimestamp) {
            return "";
        }
        try {
            const dt = new Date(this.lastFetchTimestamp);
            return dt.toLocaleString();
        } catch (e) {
            return "";
        }
    }

    get hasSearchResults() {
        return this.filteredSearchResults.length > 0;
    }

    get hasWatchlist() {
        return this.watchlist.length > 0;
    }

    get isSearchDisabled() {
        return !this.searchKeyword || this.searchKeyword.trim().length < 1 || this.isSearching;
    }

    get showSearchEmpty() {
        return !this.isSearching && this.searchResults.length === 0 && this.searchKeyword.length > 0;
    }

    get showWatchlistEmpty() {
        return !this.isRefreshing && !this.isLoadingWatchlist && this.watchlist.length === 0;
    }

    get filteredSearchResults() {
        if (this.selectedExchange === "ALL") {
            return this.searchResults;
        }
        return this.searchResults.filter((r) => {
            if (this.selectedExchange === "US") {
                return r.region === "United States";
            }
            return r.region && r.region.includes("India");
        });
    }

    get watchlistWithDisplay() {
        return this.watchlist.map((stock) => ({
            ...stock,
            week52HighDisplay: stock.week52High != null ? stock.week52High.toFixed(2) : "N/A",
            week52LowDisplay: stock.week52Low != null ? stock.week52Low.toFixed(2) : "N/A"
        }));
    }

    get hasSavedWatchlists() {
        return this.savedWatchlists.length > 0;
    }

    get savedWatchlistOptions() {
        return this.savedWatchlists.map((wl) => ({
            label: wl.Watchlist_Name__c,
            value: wl.Id
        }));
    }

    get isSaveDisabled() {
        return !this.saveAsName || this.saveAsName.trim().length === 0 || this.isSaving;
    }

    get watchlistTitle() {
        if (this.currentWatchlistName) {
            return "My Watchlist: " + this.currentWatchlistName;
        }
        return "My Watchlist";
    }

    get isDeleteDisabled() {
        return !this.selectedSavedWatchlistId;
    }

    // --- Provider handler ---

    async handleProviderChange(event) {
        const newProvider = event.detail.value;
        this.selectedProvider = newProvider;

        try {
            await setSelectedProvider({ providerName: newProvider });
            this.showToast("Provider Changed", "Now using " + (PROVIDER_LABELS[newProvider] || newProvider), "success");
        } catch (error) {
            this.showToast("Error", "Failed to save provider preference: " + this.reduceErrors(error), "error");
        }
    }

    // --- Search handlers ---

    handleSearchKeywordChange(event) {
        this.searchKeyword = event.target.value;
    }

    handleExchangeChange(event) {
        this.selectedExchange = event.detail.value;
    }

    handleSearchKeypress(event) {
        if (event.key === "Enter" && !this.isSearchDisabled) {
            this.handleSearch();
        }
    }

    async handleSearch() {
        if (this.isSearchDisabled) return;

        this.isSearching = true;
        this.searchResults = [];

        try {
            this.searchResults = await searchStocks({
                keywords: this.searchKeyword.trim(),
                providerName: this.selectedProvider
            });
        } catch (error) {
            this.handleApiError(error, "Search");
        } finally {
            this.isSearching = false;
        }
    }

    async handleAddStock(event) {
        const symbol = event.currentTarget.dataset.symbol;
        const searchResult = this.searchResults.find((r) => r.symbol === symbol);

        if (this.watchlist.some((s) => s.symbol === symbol)) {
            this.showToast("Info", symbol + " is already in your watchlist", "info");
            return;
        }

        this.isLoadingQuote = true;

        try {
            const quote = await getStockQuote({
                symbol,
                providerName: this.selectedProvider
            });
            if (searchResult) {
                if (searchResult.name && quote.name === quote.symbol) {
                    quote.name = searchResult.name;
                }
                if (!quote.currencyCode && searchResult.currencyCode) {
                    quote.currencyCode = searchResult.currencyCode;
                }
            }
            this.watchlist = [...this.watchlist, quote];
            this.showToast("Added", symbol + " added to watchlist", "success");
        } catch (error) {
            this.handleApiError(error, "Quote for " + symbol);
        } finally {
            this.isLoadingQuote = false;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === "remove") {
            this.watchlist = this.watchlist.filter((s) => s.symbol !== row.symbol);
            this.showToast("Removed", row.symbol + " removed from watchlist", "success");
        }
    }

    async handleRefreshAll() {
        if (this.watchlist.length === 0) {
            this.showToast("Info", "No stocks found to update.", "info");
            return;
        }

        this.isRefreshing = true;

        try {
            const symbols = this.watchlist.map((s) => s.symbol);
            const result = await refreshAllQuotes({
                symbolsJson: JSON.stringify(symbols),
                providerName: this.selectedProvider
            });

            const refreshedQuotes = result.quotes || [];
            const mergedList = this.watchlist.map((existing) => {
                const updated = refreshedQuotes.find((q) => q.symbol === existing.symbol);
                if (updated) {
                    if (existing.name && existing.name !== existing.symbol && updated.name === updated.symbol) {
                        updated.name = existing.name;
                    }
                    if (!updated.currencyCode && existing.currencyCode) {
                        updated.currencyCode = existing.currencyCode;
                    }
                    if (updated.changePercent === "Error") {
                        updated.priceUnavailable = true;
                    }
                    return updated;
                }
                return existing;
            });

            this.watchlist = mergedList;
            this.lastFetchTimestamp = result.lastFetchTimestamp;

            const errorCount = mergedList.filter((s) => s.changePercent === "Error").length;
            if (errorCount > 0 && errorCount < mergedList.length) {
                this.showToast(
                    "Partial Update",
                    (mergedList.length - errorCount) + " of " + mergedList.length + " stocks updated. " + errorCount + " had errors (Price Unavailable).",
                    "warning"
                );
            } else if (errorCount === 0) {
                this.showToast("Refreshed", "Watchlist quotes updated via " + (result.providerName || this.activeProviderLabel), "success");
            } else {
                this.showToast("Error", "Failed to refresh all stocks. Try switching APIs.", "error");
            }
        } catch (error) {
            this.handleApiError(error, "Refresh");
        } finally {
            this.isRefreshing = false;
        }
    }

    // --- Save/Load/Delete handlers ---

    async refreshSavedWatchlists() {
        try {
            const result = await getUserWatchlists();
            this.savedWatchlists = result || [];
        } catch (error) {
            this.savedWatchlists = [];
        }
    }

    handleOpenSaveModal() {
        this.saveAsName = this.currentWatchlistName || "";
        this.showSaveModal = true;
    }

    handleCloseSaveModal() {
        this.showSaveModal = false;
        this.saveAsName = "";
    }

    handleSaveNameChange(event) {
        this.saveAsName = event.detail.value;
    }

    async handleSaveWatchlist() {
        if (this.isSaveDisabled || this.watchlist.length === 0) return;

        this.isSaving = true;

        try {
            const items = this.watchlist.map((s) => ({
                symbol: s.symbol,
                name: s.name,
                currencyCode: s.currencyCode || null
            }));
            const itemsJson = JSON.stringify(items);

            const idToSave = this.currentWatchlistName === this.saveAsName.trim()
                ? this.currentWatchlistId
                : null;

            const savedId = await saveWatchlist({
                watchlistName: this.saveAsName.trim(),
                itemsJson: itemsJson,
                watchlistId: idToSave
            });

            this.currentWatchlistId = savedId;
            this.currentWatchlistName = this.saveAsName.trim();
            this.showSaveModal = false;
            this.saveAsName = "";

            await this.refreshSavedWatchlists();
            this.showToast("Saved", "Watchlist \"" + this.currentWatchlistName + "\" saved successfully", "success");
        } catch (error) {
            this.showToast("Save Error", this.reduceErrors(error), "error");
        } finally {
            this.isSaving = false;
        }
    }

    handleSavedWatchlistChange(event) {
        this.selectedSavedWatchlistId = event.detail.value;
    }

    async handleLoadWatchlist() {
        if (!this.selectedSavedWatchlistId) return;

        this.isLoadingWatchlist = true;

        try {
            const resultJson = await loadWatchlist({ watchlistId: this.selectedSavedWatchlistId });
            const record = JSON.parse(resultJson);

            this.currentWatchlistId = record.Id;
            this.currentWatchlistName = record.Watchlist_Name__c;

            const items = JSON.parse(record.Items_JSON__c || "[]");
            const symbols = items.map((i) => i.symbol);

            if (symbols.length === 0) {
                this.watchlist = [];
                this.showToast("Loaded", "Watchlist \"" + this.currentWatchlistName + "\" is empty", "info");
                return;
            }

            const result = await refreshAllQuotes({
                symbolsJson: JSON.stringify(symbols),
                providerName: this.selectedProvider
            });

            const loadedQuotes = result.quotes || [];
            const loadedList = items.map((item) => {
                const quote = loadedQuotes.find((q) => q.symbol === item.symbol);
                if (quote) {
                    if (item.name && quote.name === quote.symbol) {
                        quote.name = item.name;
                    }
                    if (!quote.currencyCode && item.currencyCode) {
                        quote.currencyCode = item.currencyCode;
                    }
                    return quote;
                }
                return {
                    symbol: item.symbol,
                    name: item.name || item.symbol,
                    currencyCode: item.currencyCode || null,
                    price: null,
                    dayHigh: null,
                    dayLow: null,
                    change: null,
                    changePercent: "Error",
                    week52High: null,
                    week52Low: null
                };
            });

            this.watchlist = loadedList;
            this.lastFetchTimestamp = result.lastFetchTimestamp;
            this.showToast("Loaded", "Watchlist \"" + this.currentWatchlistName + "\" loaded with live quotes", "success");
        } catch (error) {
            this.handleApiError(error, "Load");
        } finally {
            this.isLoadingWatchlist = false;
        }
    }

    async handleDeleteWatchlist() {
        if (!this.selectedSavedWatchlistId) return;

        try {
            await deleteWatchlist({ watchlistId: this.selectedSavedWatchlistId });

            if (this.currentWatchlistId === this.selectedSavedWatchlistId) {
                this.currentWatchlistId = null;
                this.currentWatchlistName = "";
            }

            this.selectedSavedWatchlistId = "";
            await this.refreshSavedWatchlists();
            this.showToast("Deleted", "Watchlist deleted", "success");
        } catch (error) {
            this.showToast("Delete Error", this.reduceErrors(error), "error");
        }
    }

    handleNewWatchlist() {
        this.watchlist = [];
        this.currentWatchlistId = null;
        this.currentWatchlistName = "";
    }

    // --- Error handling ---

    handleApiError(error, context) {
        const msg = this.reduceErrors(error);

        if (msg.toLowerCase().includes("authentication failed")) {
            this.showToast(
                "Authentication Error",
                msg + " You can switch to a different provider.",
                "error"
            );
        } else if (msg.toLowerCase().includes("rate limit")) {
            this.showToast(
                "Rate Limit",
                "Rate limit exceeded. Please wait 1 minute or switch APIs.",
                "warning"
            );
        } else if (msg.toLowerCase().includes("timed out") || msg.toLowerCase().includes("timeout")) {
            this.showToast(
                "Timeout",
                context + " request timed out. Please retry or switch to a different provider.",
                "warning"
            );
        } else if (msg.toLowerCase().includes("no stocks found")) {
            this.showToast("Info", "No stocks found to update.", "info");
        } else {
            this.showToast(context + " Error", msg, "error");
        }
    }

    // --- Utilities ---

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (!error) return "Unknown error";
        if (typeof error === "string") return error;
        if (error.body) {
            if (typeof error.body.message === "string") return error.body.message;
        }
        if (error.message) return error.message;
        return JSON.stringify(error);
    }
}
