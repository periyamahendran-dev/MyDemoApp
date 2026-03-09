import { createElement } from "lwc";
import StockWatchlist from "c/stockWatchlist";
import searchStocks from "@salesforce/apex/StockWatchlistController.searchStocks";
import getStockQuote from "@salesforce/apex/StockWatchlistController.getStockQuote";
import saveWatchlist from "@salesforce/apex/StockWatchlistController.saveWatchlist";
import getUserWatchlists from "@salesforce/apex/StockWatchlistController.getUserWatchlists";
import loadWatchlist from "@salesforce/apex/StockWatchlistController.loadWatchlist";
import deleteWatchlist from "@salesforce/apex/StockWatchlistController.deleteWatchlist";

jest.mock(
    "@salesforce/apex/StockWatchlistController.searchStocks",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/StockWatchlistController.getStockQuote",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/StockWatchlistController.saveWatchlist",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/StockWatchlistController.getUserWatchlists",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/StockWatchlistController.loadWatchlist",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/StockWatchlistController.deleteWatchlist",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_SEARCH_RESULTS = [
    { symbol: "AAPL", name: "Apple Inc", stockType: "Equity", region: "United States", currencyCode: "USD" },
    { symbol: "TCS.BSE", name: "Tata Consultancy Services", stockType: "Equity", region: "India/Bombay", currencyCode: "INR" },
    { symbol: "AMZN", name: "Amazon.com Inc", stockType: "Equity", region: "United States", currencyCode: "USD" }
];

const MOCK_QUOTE = {
    symbol: "AAPL",
    name: "Apple Inc",
    currencyCode: "USD",
    price: 228.5,
    dayHigh: 229.12,
    dayLow: 226.8,
    change: 1.5,
    changePercent: "0.6608%",
    week52High: 237.23,
    week52Low: 164.08
};

const MOCK_SAVED_WATCHLISTS = [
    { Id: "a0B000000000001", Watchlist_Name__c: "Tech Stocks" },
    { Id: "a0B000000000002", Watchlist_Name__c: "India Picks" }
];

const MOCK_LOADED_WATCHLIST = JSON.stringify({
    Id: "a0B000000000001",
    Watchlist_Name__c: "Tech Stocks",
    Items_JSON__c: JSON.stringify([
        { symbol: "AAPL", name: "Apple Inc", currencyCode: "USD" },
        { symbol: "GOOG", name: "Alphabet Inc", currencyCode: "USD" }
    ])
});

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function getSearchInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((i) => i.label === "Search Stocks");
}

function getSearchButton(element) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((b) => b.label === "Search");
}

function findButton(element, label) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((b) => b.label === label);
}

async function typeAndSearch(element, keyword) {
    const searchInput = getSearchInput(element);
    const changeEvent = new CustomEvent("change");
    Object.defineProperty(changeEvent, "target", { value: { value: keyword } });
    searchInput.dispatchEvent(changeEvent);
    await flushPromises();

    const searchBtn = getSearchButton(element);
    searchBtn.click();
    await flushPromises();
}

async function addStockToWatchlist(element) {
    searchStocks.mockResolvedValue(MOCK_SEARCH_RESULTS);
    getStockQuote.mockResolvedValue(MOCK_QUOTE);
    await typeAndSearch(element, "Apple");

    const addBtn = element.shadowRoot.querySelector('lightning-button-icon[data-symbol="AAPL"]');
    addBtn.click();
    await flushPromises();
}

describe("c-stock-watchlist", () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    function createComponent() {
        getUserWatchlists.mockResolvedValue(MOCK_SAVED_WATCHLISTS);
        const element = createElement("c-stock-watchlist", {
            is: StockWatchlist
        });
        document.body.appendChild(element);
        return element;
    }

    it("renders search input, exchange dropdown, and search button", () => {
        const element = createComponent();

        const searchInput = getSearchInput(element);
        expect(searchInput).toBeDefined();

        const combos = element.shadowRoot.querySelectorAll("lightning-combobox");
        const exchangeCombo = Array.from(combos).find((c) => c.label === "Exchange");
        expect(exchangeCombo).not.toBeNull();
        expect(exchangeCombo.options).toHaveLength(3);

        const searchBtn = getSearchButton(element);
        expect(searchBtn).toBeDefined();
    });

    it("shows empty watchlist message on load", () => {
        const element = createComponent();

        const emptyMsg = element.shadowRoot.querySelector(".empty-state");
        expect(emptyMsg).not.toBeNull();
    });

    it("disables search button when input is empty", () => {
        const element = createComponent();

        const searchBtn = getSearchButton(element);
        expect(searchBtn.disabled).toBe(true);
    });

    it("calls searchStocks when Search is clicked", async () => {
        searchStocks.mockResolvedValue(MOCK_SEARCH_RESULTS);
        const element = createComponent();

        await typeAndSearch(element, "Apple");

        expect(searchStocks).toHaveBeenCalledWith({ keywords: "Apple" });
    });

    it("displays search results after search", async () => {
        searchStocks.mockResolvedValue(MOCK_SEARCH_RESULTS);
        const element = createComponent();

        await typeAndSearch(element, "Apple");

        const resultItems = element.shadowRoot.querySelectorAll(".search-result-item");
        expect(resultItems.length).toBe(3);

        const firstSymbol = element.shadowRoot.querySelector(".result-symbol");
        expect(firstSymbol.textContent).toBe("AAPL");
    });

    it("filters search results by US exchange", async () => {
        searchStocks.mockResolvedValue(MOCK_SEARCH_RESULTS);
        const element = createComponent();

        const combos = element.shadowRoot.querySelectorAll("lightning-combobox");
        const exchangeCombo = Array.from(combos).find((c) => c.label === "Exchange");
        exchangeCombo.dispatchEvent(
            new CustomEvent("change", { detail: { value: "US" } })
        );
        await flushPromises();

        await typeAndSearch(element, "test");

        const resultItems = element.shadowRoot.querySelectorAll(".search-result-item");
        expect(resultItems.length).toBe(2);
    });

    it("adds stock to watchlist when + button is clicked", async () => {
        const element = createComponent();
        await addStockToWatchlist(element);

        expect(getStockQuote).toHaveBeenCalledWith({ symbol: "AAPL" });

        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].symbol).toBe("AAPL");
    });

    it("shows Save and Refresh All buttons when watchlist has items", async () => {
        const element = createComponent();
        await addStockToWatchlist(element);

        const saveBtn = findButton(element, "Save");
        expect(saveBtn).toBeDefined();

        const refreshBtn = findButton(element, "Refresh All");
        expect(refreshBtn).toBeDefined();
    });

    it("shows API rate limit note", () => {
        const element = createComponent();

        const note = element.shadowRoot.querySelector(".api-note");
        expect(note).not.toBeNull();
        expect(note.textContent).toContain("Alpha Vantage");
    });

    it("renders watchlist datatable with correct columns", async () => {
        const element = createComponent();
        await addStockToWatchlist(element);

        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        const colLabels = datatable.columns
            .filter((c) => c.label)
            .map((c) => c.label);
        expect(colLabels).toContain("Symbol");
        expect(colLabels).toContain("Price");
        expect(colLabels).toContain("Currency");
        expect(colLabels).toContain("Day High");
        expect(colLabels).toContain("Day Low");
        expect(colLabels).toContain("52W High");
        expect(colLabels).toContain("52W Low");
        expect(colLabels).toContain("Change %");
    });

    it("renders saved watchlists combobox", async () => {
        const element = createComponent();
        await flushPromises();

        const combos = element.shadowRoot.querySelectorAll("lightning-combobox");
        const savedCombo = Array.from(combos).find((c) => c.label === "Saved Watchlists");
        expect(savedCombo).toBeDefined();
    });

    it("loads getUserWatchlists on init", async () => {
        createComponent();
        await flushPromises();

        expect(getUserWatchlists).toHaveBeenCalled();
    });

    it("renders Load, Delete, and New buttons", async () => {
        const element = createComponent();
        await flushPromises();

        const loadBtn = findButton(element, "Load");
        expect(loadBtn).toBeDefined();

        const deleteBtn = findButton(element, "Delete");
        expect(deleteBtn).toBeDefined();

        const newBtn = findButton(element, "New");
        expect(newBtn).toBeDefined();
    });

    it("opens save modal when Save is clicked", async () => {
        const element = createComponent();
        await addStockToWatchlist(element);

        const saveBtn = findButton(element, "Save");
        saveBtn.click();
        await flushPromises();

        const modal = element.shadowRoot.querySelector(".slds-modal");
        expect(modal).not.toBeNull();

        const modalInputs = element.shadowRoot.querySelectorAll("lightning-input");
        const nameInput = Array.from(modalInputs).find((i) => i.label === "Watchlist Name");
        expect(nameInput).toBeDefined();
    });

    it("calls saveWatchlist when Save is confirmed in modal", async () => {
        saveWatchlist.mockResolvedValue("a0B000000000001");
        getUserWatchlists.mockResolvedValue(MOCK_SAVED_WATCHLISTS);
        const element = createComponent();
        await addStockToWatchlist(element);

        const saveBtn = findButton(element, "Save");
        saveBtn.click();
        await flushPromises();

        const modalInputs = element.shadowRoot.querySelectorAll("lightning-input");
        const nameInput = Array.from(modalInputs).find((i) => i.label === "Watchlist Name");
        nameInput.dispatchEvent(
            new CustomEvent("change", { detail: { value: "My Tech Stocks" } })
        );
        await flushPromises();

        const allBtns = element.shadowRoot.querySelectorAll("lightning-button");
        const modalSaveBtn = Array.from(allBtns).find(
            (b) => b.variant === "brand" && b.label === "Save" && b.closest(".slds-modal")
        );
        modalSaveBtn.click();
        await flushPromises();

        expect(saveWatchlist).toHaveBeenCalledWith(
            expect.objectContaining({
                watchlistName: "My Tech Stocks"
            })
        );
    });

    it("calls loadWatchlist and fetches quotes when Load is clicked", async () => {
        loadWatchlist.mockResolvedValue(MOCK_LOADED_WATCHLIST);
        getStockQuote.mockResolvedValue(MOCK_QUOTE);
        const element = createComponent();
        await flushPromises();

        const combos = element.shadowRoot.querySelectorAll("lightning-combobox");
        const savedCombo = Array.from(combos).find((c) => c.label === "Saved Watchlists");
        savedCombo.dispatchEvent(
            new CustomEvent("change", { detail: { value: "a0B000000000001" } })
        );
        await flushPromises();

        const loadBtn = findButton(element, "Load");
        loadBtn.click();
        await flushPromises();

        expect(loadWatchlist).toHaveBeenCalledWith({ watchlistId: "a0B000000000001" });
    });

    it("calls deleteWatchlist when Delete is clicked", async () => {
        deleteWatchlist.mockResolvedValue();
        getUserWatchlists.mockResolvedValue([]);
        const element = createComponent();
        await flushPromises();

        const combos = element.shadowRoot.querySelectorAll("lightning-combobox");
        const savedCombo = Array.from(combos).find((c) => c.label === "Saved Watchlists");
        savedCombo.dispatchEvent(
            new CustomEvent("change", { detail: { value: "a0B000000000001" } })
        );
        await flushPromises();

        const deleteBtn = findButton(element, "Delete");
        deleteBtn.click();
        await flushPromises();

        expect(deleteWatchlist).toHaveBeenCalledWith({ watchlistId: "a0B000000000001" });
    });

    it("clears watchlist when New button is clicked", async () => {
        const element = createComponent();
        await addStockToWatchlist(element);

        let datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable.data).toHaveLength(1);

        const newBtn = findButton(element, "New");
        newBtn.click();
        await flushPromises();

        datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable).toBeNull();

        const emptyMsg = element.shadowRoot.querySelector(".empty-state");
        expect(emptyMsg).not.toBeNull();
    });
});
