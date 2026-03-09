import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSupportedCurrencies from "@salesforce/apex/CurrencyConverterController.getSupportedCurrencies";
import convertCurrency from "@salesforce/apex/CurrencyConverterController.convertCurrency";
import getExchangeRate from "@salesforce/apex/CurrencyConverterController.getExchangeRate";
import getConversionHistory from "@salesforce/apex/CurrencyConverterController.getConversionHistory";
import deleteConversionHistory from "@salesforce/apex/CurrencyConverterController.deleteConversionHistory";
import MASCOT_ASTRO from "@salesforce/resourceUrl/MascotAstro";
import MASCOT_CODEY from "@salesforce/resourceUrl/MascotCodey";
import MASCOT_EINSTEIN from "@salesforce/resourceUrl/MascotEinstein";

const PROVIDER_OPTIONS = [
    { label: "ExchangeRate-API", value: "EXCHANGE_RATE_API" },
    { label: "Frankfurter (ECB)", value: "FRANKFURTER" },
    { label: "Fawaz Ahmed", value: "FAWAZ_AHMED" }
];

const PROVIDER_LABEL_MAP = {};
PROVIDER_OPTIONS.forEach((opt) => {
    PROVIDER_LABEL_MAP[opt.value] = opt.label;
});

const RATE_DEBOUNCE_MS = 300;

const HISTORY_LIMIT_OPTIONS = [
    { label: "Recent 10", value: "10" },
    { label: "Recent 25", value: "25" },
    { label: "Recent 50", value: "50" },
    { label: "Recent 100", value: "100" }
];

const HISTORY_COLUMNS = [
    {
        label: "Date",
        fieldName: "Conversion_Date__c",
        type: "date",
        typeAttributes: {
            year: "numeric",
            month: "short",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit"
        },
        sortable: true
    },
    { label: "From", fieldName: "From_Currency__c", type: "text" },
    { label: "To", fieldName: "To_Currency__c", type: "text" },
    {
        label: "Amount",
        fieldName: "Amount__c",
        type: "number",
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    },
    {
        label: "Converted",
        fieldName: "Converted_Amount__c",
        type: "number",
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    },
    {
        label: "Rate",
        fieldName: "Exchange_Rate__c",
        type: "number",
        typeAttributes: { minimumFractionDigits: 6, maximumFractionDigits: 6 }
    },
    { label: "Provider", fieldName: "Rate_Provider__c", type: "text" },
    {
        type: "action",
        typeAttributes: {
            rowActions: [{ label: "Delete", name: "delete" }]
        }
    }
];

export default class CurrencyConverter extends LightningElement {
    amount = null;
    fromCurrency = "USD";
    toCurrency = "EUR";
    selectedProvider = "EXCHANGE_RATE_API";
    isLoading = false;
    isLoadingRate = false;
    previewRate = null;
    previewError = null;

    @track conversionResult = null;
    @track currencyOptions = [];
    @track conversionHistory = [];

    providerOptions = PROVIDER_OPTIONS;
    historyColumns = HISTORY_COLUMNS;
    historyLimitOptions = HISTORY_LIMIT_OPTIONS;
    historyLimit = 10;
    isLoadingHistory = false;
    _rateDebounceTimer;

    get mascotAstroUrl() {
        return MASCOT_ASTRO;
    }
    get mascotCodeyUrl() {
        return MASCOT_CODEY;
    }
    get mascotEinsteinUrl() {
        return MASCOT_EINSTEIN;
    }

    connectedCallback() {
        this.loadCurrencies();
        this.loadConversionHistory();
        this.debounceFetchPreviewRate();
    }

    async loadCurrencies() {
        try {
            const data = await getSupportedCurrencies({ provider: this.selectedProvider });
            this.currencyOptions = data.map((code) => ({
                label: code,
                value: code
            }));
        } catch (error) {
            this.showToast("Error", "Failed to load currencies: " + this.reduceErrors(error), "error");
        }
    }

    get isConvertDisabled() {
        return (
            !this.amount ||
            this.amount <= 0 ||
            !this.fromCurrency ||
            !this.toCurrency ||
            this.isLoading
        );
    }

    get hasHistory() {
        return this.conversionHistory && this.conversionHistory.length > 0;
    }

    get showHistoryEmpty() {
        return !this.isLoadingHistory && !this.hasHistory;
    }

    get showRatePreview() {
        return this.fromCurrency && this.toCurrency && this.fromCurrency !== this.toCurrency;
    }

    get selectedProviderLabel() {
        return PROVIDER_LABEL_MAP[this.selectedProvider] || this.selectedProvider;
    }

    get formattedPreviewRate() {
        if (!this.previewRate) return "";
        return new Intl.NumberFormat(undefined, {
            minimumFractionDigits: 4,
            maximumFractionDigits: 6
        }).format(this.previewRate);
    }

    get formattedOriginalAmount() {
        if (!this.conversionResult) return "";
        return new Intl.NumberFormat(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(this.conversionResult.originalAmount);
    }

    get formattedConvertedAmount() {
        if (!this.conversionResult) return "";
        return new Intl.NumberFormat(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(this.conversionResult.convertedAmount);
    }

    handleAmountChange(event) {
        this.amount = event.detail.value;
    }

    handleFromCurrencyChange(event) {
        this.fromCurrency = event.detail.value;
        this.debounceFetchPreviewRate();
    }

    handleToCurrencyChange(event) {
        this.toCurrency = event.detail.value;
        this.debounceFetchPreviewRate();
    }

    handleProviderChange(event) {
        this.selectedProvider = event.detail.value;
        this.loadCurrencies();
        this.debounceFetchPreviewRate();
    }

    handleSwap() {
        const temp = this.fromCurrency;
        this.fromCurrency = this.toCurrency;
        this.toCurrency = temp;
        this.debounceFetchPreviewRate();
    }

    debounceFetchPreviewRate() {
        clearTimeout(this._rateDebounceTimer);
        this._rateDebounceTimer = setTimeout(() => {
            this.fetchPreviewRate();
        }, RATE_DEBOUNCE_MS);
    }

    async fetchPreviewRate() {
        if (!this.fromCurrency || !this.toCurrency || this.fromCurrency === this.toCurrency) {
            this.previewRate = null;
            this.previewError = null;
            return;
        }

        this.isLoadingRate = true;
        this.previewError = null;

        try {
            this.previewRate = await getExchangeRate({
                fromCurrency: this.fromCurrency,
                toCurrency: this.toCurrency,
                provider: this.selectedProvider
            });
        } catch (error) {
            this.previewRate = null;
            this.previewError = this.reduceErrors(error);
        } finally {
            this.isLoadingRate = false;
        }
    }

    async handleConvert() {
        if (this.isConvertDisabled) return;

        this.isLoading = true;
        this.conversionResult = null;

        try {
            this.conversionResult = await convertCurrency({
                fromCurrency: this.fromCurrency,
                toCurrency: this.toCurrency,
                amount: parseFloat(this.amount),
                provider: this.selectedProvider
            });
            this.showToast("Success", "Conversion completed successfully", "success");
            await this.loadConversionHistory();
        } catch (error) {
            this.showToast("Conversion Error", this.reduceErrors(error), "error");
        } finally {
            this.isLoading = false;
        }
    }

    get selectedHistoryLimit() {
        return String(this.historyLimit);
    }

    handleHistoryLimitChange(event) {
        this.historyLimit = parseInt(event.detail.value, 10);
        this.loadConversionHistory();
    }

    async loadConversionHistory() {
        this.isLoadingHistory = true;
        try {
            this.conversionHistory = await getConversionHistory({ recordLimit: this.historyLimit });
        } catch (error) {
            this.showToast("Error", "Failed to load history: " + this.reduceErrors(error), "error");
        } finally {
            this.isLoadingHistory = false;
        }
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === "delete") {
            try {
                await deleteConversionHistory({ recordId: row.Id });
                this.showToast("Success", "Record deleted", "success");
                await this.loadConversionHistory();
            } catch (error) {
                this.showToast("Error", "Failed to delete: " + this.reduceErrors(error), "error");
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (!error) return "Unknown error";
        if (typeof error === "string") return error;
        if (error.body) {
            if (typeof error.body.message === "string") return error.body.message;
            if (error.body.fieldErrors) {
                return Object.values(error.body.fieldErrors)
                    .flat()
                    .map((e) => e.message)
                    .join(", ");
            }
        }
        if (error.message) return error.message;
        return JSON.stringify(error);
    }
}
