page 50104 "PTE Invest Role Center"
{
    Caption = 'Investment Manager';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            group(InvestOverview)
            {
                ShowCaption = false;

                part(Activities; "PTE Invest Activities")
                {
                    ApplicationArea = All;
                }
                part(LatestExchangeRates; "PTE Latest Exchange Rates")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(BrokerReports)
            {
                Caption = 'Broker Reports';

                action(Brokers)
                {
                    ApplicationArea = All;
                    Caption = 'Brokers';
                    RunObject = page "PTE Brokers";
                    ToolTip = 'Open the list of investment brokers.';
                }
                action(BrokerEntries)
                {
                    ApplicationArea = All;
                    Caption = 'Broker Entries';
                    RunObject = page "PTE Broker Entries";
                    ToolTip = 'Open permanent investment entries imported or created from broker reports.';
                }
                action(BrokerImports)
                {
                    ApplicationArea = All;
                    Caption = 'Broker Imports';
                    RunObject = page "PTE Broker Imports";
                    ToolTip = 'Open broker report import previews and history.';
                }
            }
            group(Currency)
            {
                Caption = 'Currency';
                action(Currencies)
                {
                    ApplicationArea = All;
                    Caption = 'Currencies';
                    RunObject = page Currencies;
                    ToolTip = 'Open currencies and select the exchange rate source used by Invest.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';

                action(InvestSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Invest Setup';
                    RunObject = page "PTE Invest Setup";
                    ToolTip = 'Open investment import and tax calculation setup.';
                }
                action(InstrumentTaxCountries)
                {
                    ApplicationArea = All;
                    Caption = 'Instrument Tax Countries';
                    RunObject = page "PTE Instrument Tax Countries";
                    ToolTip = 'Open ticker country mappings used by PIT calculations.';
                }
            }
            group(Taxes)
            {
                Caption = 'Taxes';

                action(PITCalculations)
                {
                    ApplicationArea = All;
                    Caption = 'PIT Calculations';
                    RunObject = page "PTE PIT Calculations";
                    ToolTip = 'Open PIT-38 and PIT/ZG calculation history.';
                }
            }
        }
        area(Creation)
        {
            action(NewBroker)
            {
                ApplicationArea = All;
                Caption = 'Broker';
                RunObject = page "PTE Broker Card";
                RunPageMode = Create;
                ToolTip = 'Create a new broker.';
            }
            action(NewBrokerEntry)
            {
                ApplicationArea = All;
                Caption = 'Broker Entry';
                RunObject = page "PTE Broker Entries";
                RunPageMode = Create;
                ToolTip = 'Create a new broker entry manually.';
            }
        }
        area(Processing)
        {
            action(ImportBrokerReport)
            {
                ApplicationArea = All;
                Caption = 'Import Broker Report';
                RunObject = report "PTE Import Broker Report";
                ToolTip = 'Import and validate a broker report before creating permanent broker entries.';
            }
            action(ImportFXRates)
            {
                ApplicationArea = All;
                Caption = 'Update Exchange Rates';
                Image = RefreshLines;
                RunObject = report "PTE Import Exchange Rates";
                ToolTip = 'Import or update exchange rates by using the sources selected on currency cards.';
            }
            action(CalculatePIT)
            {
                ApplicationArea = All;
                Caption = 'Calculate PIT';
                RunObject = report "PTE Calculate PIT";
                ToolTip = 'Calculate PIT-38 and PIT/ZG from broker entries.';
            }
        }
        area(Reporting)
        {
            action(PITSourceEntries)
            {
                ApplicationArea = All;
                Caption = 'PIT Source Entries';
                RunObject = page "PTE Broker Entries";
                ToolTip = 'Open broker entries that will be used as the source for PIT-38 and PIT-ZG calculations.';
            }
        }
    }
}