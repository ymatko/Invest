page 50114 "PTE Broker Import Lines"
{
    ApplicationArea = All;
    Caption = 'Broker Import Lines';
    PageType = ListPart;
    SourceTable = "PTE Broker Import Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the line is selected for import.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the validation or import status.';
                }
                field("Validation Message"; Rec."Validation Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the validation message for this line.';
                }
                field("Provider Error"; Rec."Provider Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the line contains an error detected by the broker report parser.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the source file line number.';
                }
                field("Trade Date"; Rec."Trade Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the trade date.';
                }
                field("Broker Account No."; Rec."Broker Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker account number from the report.';
                }
                field("Source Transaction Type"; Rec."Source Transaction Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction type from the source report.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the normalized transaction type.';
                }
                field(Ticker; Rec.Ticker)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ticker from the source report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction description.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity.';
                }
                field(Price; Rec.Price)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price.';
                }
                field("Price Currency Code"; Rec."Price Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price currency from the source report.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of imported amounts.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the gross amount in imported amount currency.';
                }
                field("Fee Amount"; Rec."Fee Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fee amount in imported amount currency.';
                }
                field("Net Amount"; Rec."Net Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the net amount in imported amount currency.';
                }
                field("Exchange Rate"; Rec."Exchange Rate")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the exchange rate used for local currency amounts.';
                }
                field("LCY Net Amount"; Rec."LCY Net Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the net amount in local currency.';
                }
                field("Broker Entry No."; Rec."Broker Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the permanent broker entry created from this line.';
                }
            }
        }
    }
}