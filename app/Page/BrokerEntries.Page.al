page 50103 "PTE Broker Entries"
{
    ApplicationArea = All;
    Caption = 'Broker Entries';
    PageType = List;
    SourceTable = "PTE Broker Entry";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Broker Code"; Rec."Broker Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker that owns this entry.';
                }
                field("External Entry ID"; Rec."External Entry ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the transaction identifier from the broker report.';
                }
                field("Broker Account No."; Rec."Broker Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker account number from the report.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of broker transaction.';
                }
                field("Source Transaction Type"; Rec."Source Transaction Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the original transaction type from the broker report.';
                }
                field("Instrument Type"; Rec."Instrument Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the investment instrument type.';
                }
                field("Trade Date"; Rec."Trade Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the trade date from the broker report.';
                }
                field("Settlement Date"; Rec."Settlement Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the settlement date from the broker report.';
                }
                field("Tax Year"; Rec."Tax Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax year used by PIT calculations.';
                }
                field(ISIN; Rec.ISIN)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISIN from the broker report.';
                }
                field(Ticker; Rec.Ticker)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ticker from the broker report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker entry description.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region used for PIT-ZG grouping.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity from the broker report.';
                }
                field(Price; Rec.Price)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price from the broker report.';
                }
                field("Price Currency Code"; Rec."Price Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price currency from the broker report.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction currency.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the gross transaction amount in transaction currency.';
                }
                field("Fee Amount"; Rec."Fee Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fee amount in transaction currency.';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax amount in transaction currency.';
                }
                field("Net Amount"; Rec."Net Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the net transaction amount in transaction currency.';
                }
                field("Exchange Rate"; Rec."Exchange Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the exchange rate used for local currency amounts.';
                }
                field("LCY Gross Amount"; Rec."LCY Gross Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the gross transaction amount in local currency.';
                }
                field("LCY Fee Amount"; Rec."LCY Fee Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fee amount in local currency.';
                }
                field("LCY Tax Amount"; Rec."LCY Tax Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax amount in local currency.';
                }
                field("LCY Net Amount"; Rec."LCY Net Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the net transaction amount in local currency.';
                }
                field("Import Batch No."; Rec."Import Batch No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the import batch that created this broker entry.';
                }
                field("Broker Import Entry No."; Rec."Broker Import Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker import preview that created this broker entry.';
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the source file name from which this entry was imported.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source file line number from which this entry was imported.';
                }
            }
        }
    }
}