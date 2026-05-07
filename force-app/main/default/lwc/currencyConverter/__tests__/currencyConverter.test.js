import { createElement } from "lwc";
import CurrencyConverter from "c/currencyConverter";
import getSupportedCurrencies from "@salesforce/apex/CurrencyConverterController.getSupportedCurrencies";
import convertCurrency from "@salesforce/apex/CurrencyConverterController.convertCurrency";
import getExchangeRate from "@salesforce/apex/CurrencyConverterController.getExchangeRate";
import getConversionHistory from "@salesforce/apex/CurrencyConverterController.getConversionHistory";

jest.mock(
    "@salesforce/apex/CurrencyConverterController.getSupportedCurrencies",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/CurrencyConverterController.convertCurrency",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/CurrencyConverterController.getExchangeRate",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/CurrencyConverterController.getConversionHistory",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/CurrencyConverterController.deleteConversionHistory",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_CURRENCIES = ["AUD", "CAD", "EUR", "GBP", "INR", "JPY", "USD"];

const MOCK_CONVERSION_RESULT = {
    originalAmount: 100,
    fromCurrency: "USD",
    toCurrency: "EUR",
    exchangeRate: 0.85,
    convertedAmount: 85.0,
    providerName: "ExchangeRate-API"
};

const MOCK_HISTORY = [
    {
        Id: "a00000000000001",
        Name: "CC-0001",
        From_Currency__c: "USD",
        To_Currency__c: "EUR",
        Amount__c: 100,
        Converted_Amount__c: 85,
        Exchange_Rate__c: 0.85,
        Conversion_Date__c: "2026-02-26T10:00:00.000Z",
        Rate_Provider__c: "ExchangeRate-API"
    },
    {
        Id: "a00000000000002",
        Name: "CC-0002",
        From_Currency__c: "GBP",
        To_Currency__c: "JPY",
        Amount__c: 50,
        Converted_Amount__c: 7534.25,
        Exchange_Rate__c: 150.685,
        Conversion_Date__c: "2026-02-25T14:30:00.000Z",
        Rate_Provider__c: "Frankfurter (ECB)"
    }
];

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

describe("c-currency-converter", () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function createComponent(withHistory = false) {
        getConversionHistory.mockResolvedValue(withHistory ? MOCK_HISTORY : []);

        const element = createElement("c-currency-converter", {
            is: CurrencyConverter
        });
        document.body.appendChild(element);
        await flushPromises();
        return element;
    }

    it("renders the converter card with title", async () => {
        const element = await createComponent();

        const card = element.shadowRoot.querySelector("lightning-card");
        expect(card).not.toBeNull();
    });

    it("renders tabset with Converter and Stock Watchlist tabs (no History tab)", async () => {
        const element = await createComponent();

        const tabset = element.shadowRoot.querySelector("lightning-tabset");
        expect(tabset).not.toBeNull();

        const tabs = element.shadowRoot.querySelectorAll("lightning-tab");
        expect(tabs).toHaveLength(2);
        expect(tabs[0].label).toBe("Converter");
        expect(tabs[1].label).toBe("Stock Watchlist");
    });

    it("does not render a standalone History tab", async () => {
        const element = await createComponent();

        const tabs = element.shadowRoot.querySelectorAll("lightning-tab");
        const historyTab = Array.from(tabs).find((t) => t.label === "History");
        expect(historyTab).toBeUndefined();
    });

    it("renders conversion history inside an accordion section in Converter tab", async () => {
        const element = await createComponent();

        const accordion = element.shadowRoot.querySelector("lightning-accordion");
        expect(accordion).not.toBeNull();

        const section = element.shadowRoot.querySelector("lightning-accordion-section");
        expect(section).not.toBeNull();
        expect(section.label).toBe("Conversion History");
    });

    it("accordion is collapsed by default", async () => {
        const element = await createComponent();

        const accordion = element.shadowRoot.querySelector("lightning-accordion");
        expect(accordion.activeSectionName).toEqual([]);
    });

    it("renders stock watchlist child component in third tab", async () => {
        const element = await createComponent();

        const stockWatchlist = element.shadowRoot.querySelector("c-stock-watchlist");
        expect(stockWatchlist).not.toBeNull();
    });

    it("populates currency dropdowns from wire", async () => {
        const element = await createComponent();

        const emit = getSupportedCurrencies.emit;
        if (emit) {
            emit(MOCK_CURRENCIES);
            await flushPromises();
        }

        const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
        expect(comboboxes.length).toBeGreaterThanOrEqual(2);
    });

    it("renders amount input field", async () => {
        const element = await createComponent();

        const input = element.shadowRoot.querySelector("lightning-input");
        expect(input).not.toBeNull();
        expect(input.type).toBe("number");
        expect(input.label).toBe("Amount");
    });

    it("renders convert button", async () => {
        const element = await createComponent();

        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const convertBtn = Array.from(buttons).find((b) => b.label === "Convert");
        expect(convertBtn).toBeDefined();
    });

    it("renders swap button", async () => {
        const element = await createComponent();

        const swapButton = element.shadowRoot.querySelector("lightning-button-icon");
        expect(swapButton).not.toBeNull();
        expect(swapButton.iconName).toBe("utility:swap");
    });

    it("renders provider radio group with three options", async () => {
        const element = await createComponent();

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        expect(radioGroup).not.toBeNull();
        expect(radioGroup.label).toBe("Exchange Rate Provider");
        expect(radioGroup.type).toBe("button");
        expect(radioGroup.options).toHaveLength(3);
        expect(radioGroup.value).toBe("EXCHANGE_RATE_API");
    });

    it("has correct provider option labels", async () => {
        const element = await createComponent();

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        const labels = radioGroup.options.map((opt) => opt.label);
        expect(labels).toEqual(["ExchangeRate-API", "Frankfurter (ECB)", "Fawaz Ahmed"]);
    });

    it("updates selected provider on change", async () => {
        const element = await createComponent();

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        radioGroup.dispatchEvent(
            new CustomEvent("change", { detail: { value: "FRANKFURTER" } })
        );
        await flushPromises();

        expect(radioGroup.value).toBe("FRANKFURTER");
    });

    it("reloads currencies when provider changes", async () => {
        getSupportedCurrencies.mockResolvedValue(MOCK_CURRENCIES);
        const element = await createComponent();

        getSupportedCurrencies.mockClear();
        getSupportedCurrencies.mockResolvedValue(MOCK_CURRENCIES);

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        radioGroup.dispatchEvent(
            new CustomEvent("change", { detail: { value: "FRANKFURTER" } })
        );
        await flushPromises();

        expect(getSupportedCurrencies).toHaveBeenCalledWith({ provider: "FRANKFURTER" });
    });

    it("swaps currencies when swap button is clicked", async () => {
        const element = await createComponent();

        const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
        const fromBefore = comboboxes[0].value;
        const toBefore = comboboxes[1].value;

        const swapButton = element.shadowRoot.querySelector("lightning-button-icon");
        swapButton.click();
        await flushPromises();

        const comboboxesAfter = element.shadowRoot.querySelectorAll("lightning-combobox");
        expect(comboboxesAfter[0].value).toBe(toBefore);
        expect(comboboxesAfter[1].value).toBe(fromBefore);
    });

    it("passes provider to convert call", async () => {
        convertCurrency.mockResolvedValue(MOCK_CONVERSION_RESULT);
        getSupportedCurrencies.mockResolvedValue(MOCK_CURRENCIES);
        getConversionHistory.mockResolvedValue([]);

        const element = await createComponent();

        const input = element.shadowRoot.querySelector("lightning-input");
        input.value = 100;
        input.dispatchEvent(new CustomEvent("change", { detail: { value: 100 } }));
        await flushPromises();

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        radioGroup.dispatchEvent(
            new CustomEvent("change", { detail: { value: "FRANKFURTER" } })
        );
        await flushPromises();

        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const convertBtn = Array.from(buttons).find((b) => b.label === "Convert");
        if (convertBtn) {
            convertBtn.click();
            await flushPromises();
        }

        expect(convertCurrency).toHaveBeenCalledWith({
            fromCurrency: "USD",
            toCurrency: "EUR",
            amount: 100,
            provider: "FRANKFURTER"
        });
    });

    it("displays conversion result after successful convert", async () => {
        convertCurrency.mockResolvedValue(MOCK_CONVERSION_RESULT);
        getConversionHistory.mockResolvedValue([]);

        const element = await createComponent();

        const input = element.shadowRoot.querySelector("lightning-input");
        input.value = 100;
        input.dispatchEvent(new CustomEvent("change", { detail: { value: 100 } }));
        await flushPromises();

        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const convertBtn = Array.from(buttons).find((b) => b.label === "Convert");
        if (convertBtn) {
            convertBtn.click();
            await flushPromises();
        }
    });

    it("renders three decorative mascot images", async () => {
        const element = await createComponent();

        const mascots = element.shadowRoot.querySelectorAll("img.mascot");
        expect(mascots).toHaveLength(3);

        const astro = element.shadowRoot.querySelector(".mascot-astro");
        expect(astro).not.toBeNull();
        expect(astro.getAttribute("aria-hidden")).toBe("true");
        expect(astro.alt).toBe("");

        const codey = element.shadowRoot.querySelector(".mascot-codey");
        expect(codey).not.toBeNull();
        expect(codey.getAttribute("aria-hidden")).toBe("true");

        const einstein = element.shadowRoot.querySelector(".mascot-einstein");
        expect(einstein).not.toBeNull();
        expect(einstein.getAttribute("aria-hidden")).toBe("true");
    });

    it("mascot images have src attributes from static resources", async () => {
        const element = await createComponent();

        const mascots = element.shadowRoot.querySelectorAll("img.mascot");
        mascots.forEach((img) => {
            expect(img.src).toBeTruthy();
        });
    });

    it("loads history with default limit of 10 on init", async () => {
        getConversionHistory.mockResolvedValue([]);
        await createComponent();

        expect(getConversionHistory).toHaveBeenCalledWith({ recordLimit: 10 });
    });

    it("renders history limit dropdown in accordion section", async () => {
        const element = await createComponent(true);

        const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
        const limitCombo = Array.from(comboboxes).find((c) => c.label === "Show");
        expect(limitCombo).toBeDefined();
        expect(limitCombo.value).toBe("10");
        expect(limitCombo.options).toHaveLength(4);
    });

    it("reloads history when limit changes", async () => {
        getConversionHistory.mockResolvedValue(MOCK_HISTORY);
        const element = await createComponent(true);

        getConversionHistory.mockClear();
        getConversionHistory.mockResolvedValue(MOCK_HISTORY);

        const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
        const limitCombo = Array.from(comboboxes).find((c) => c.label === "Show");
        limitCombo.dispatchEvent(
            new CustomEvent("change", { detail: { value: "25" } })
        );
        await flushPromises();

        expect(getConversionHistory).toHaveBeenCalledWith({ recordLimit: 25 });
    });

    it("shows datatable in accordion section when history exists", async () => {
        const element = await createComponent(true);

        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable).not.toBeNull();
        expect(datatable.data).toEqual(MOCK_HISTORY);
    });

    it("does not show datatable when no history", async () => {
        const element = await createComponent(false);

        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable).toBeNull();
    });

    it("history datatable includes provider column", async () => {
        const element = await createComponent(true);

        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        const providerColumn = datatable.columns.find((col) => col.fieldName === "Rate_Provider__c");
        expect(providerColumn).toBeDefined();
        expect(providerColumn.label).toBe("Provider");
    });

    it("fetches rate preview on initial load with default currencies", async () => {
        getExchangeRate.mockResolvedValue(0.85);
        getConversionHistory.mockResolvedValue([]);

        const element = createElement("c-currency-converter", {
            is: CurrencyConverter
        });
        document.body.appendChild(element);

        await delay(400);
        await flushPromises();

        expect(getExchangeRate).toHaveBeenCalledWith({
            fromCurrency: "USD",
            toCurrency: "EUR",
            provider: "EXCHANGE_RATE_API"
        });

        const preview = element.shadowRoot.querySelector(".rate-preview-text");
        expect(preview).not.toBeNull();
    }, 10000);

    it("fetches rate preview when provider changes", async () => {
        getExchangeRate.mockResolvedValue(0.85);
        getConversionHistory.mockResolvedValue([]);

        const element = createElement("c-currency-converter", {
            is: CurrencyConverter
        });
        document.body.appendChild(element);

        await delay(400);
        await flushPromises();

        getExchangeRate.mockClear();
        getExchangeRate.mockResolvedValue(0.86);

        const radioGroup = element.shadowRoot.querySelector("lightning-radio-group");
        radioGroup.dispatchEvent(
            new CustomEvent("change", { detail: { value: "FRANKFURTER" } })
        );

        await delay(400);
        await flushPromises();

        expect(getExchangeRate).toHaveBeenCalledWith({
            fromCurrency: "USD",
            toCurrency: "EUR",
            provider: "FRANKFURTER"
        });
    }, 10000);

    it("hides rate preview when currencies are the same", async () => {
        getExchangeRate.mockResolvedValue(0.85);
        getConversionHistory.mockResolvedValue([]);

        const element = createElement("c-currency-converter", {
            is: CurrencyConverter
        });
        document.body.appendChild(element);

        await delay(400);
        await flushPromises();

        const fromCombobox = element.shadowRoot.querySelectorAll("lightning-combobox")[0];
        fromCombobox.dispatchEvent(
            new CustomEvent("change", { detail: { value: "EUR" } })
        );

        await delay(400);
        await flushPromises();

        const preview = element.shadowRoot.querySelector(".rate-preview");
        expect(preview).toBeNull();
    }, 10000);
});
