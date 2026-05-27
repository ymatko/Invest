page 50122 "PTE PIT Calc. Lines"
{
    ApplicationArea = All;
    Caption = 'PIT Calculation Lines';
    PageType = ListPart;
    SourceTable = "PTE PIT Calc. Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line type.';
                }
                field("Form Name"; Rec."Form Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the form name.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region code.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PIT field number.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PIT field caption.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculated amount.';
                }
                field("Text Value"; Rec."Text Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text value.';
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculation note.';
                }
            }
        }
    }
}