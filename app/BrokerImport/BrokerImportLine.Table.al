table 50113 "PTE Broker Import Line"
{
    Caption = 'Broker Import Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Import Entry No."; Integer)
        {
            Caption = 'Import Entry No.';
            TableRelation = "PTE Broker Import Header"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Selected; Boolean)
        {
            Caption = 'Selected';
            InitValue = true;
        }
        field(20; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Valid,Error,Imported,Skipped';
            OptionMembers = New,Valid,Error,Imported,Skipped;
        }
        field(30; "Validation Message"; Text[250])
        {
            Caption = 'Validation Message';
        }
        field(35; "Provider Error"; Boolean)
        {
            Caption = 'Provider Error';
        }
        field(40; "Broker Code"; Code[20])
        {
            Caption = 'Broker Code';
            TableRelation = "PTE Broker".Code;
        }
        field(50; "Broker Account No."; Text[50])
        {
            Caption = 'Broker Account No.';
        }
        field(60; "External Entry ID"; Text[100])
        {
            Caption = 'External Entry ID';
        }
        field(70; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'Buy,Sell,Dividend,Interest,Fee,Tax,Deposit,Withdrawal,Other';
            OptionMembers = Buy,Sell,Dividend,Interest,Fee,Tax,Deposit,Withdrawal,Other;
        }
        field(80; "Source Transaction Type"; Text[50])
        {
            Caption = 'Source Transaction Type';
        }
        field(90; "Instrument Type"; Option)
        {
            Caption = 'Instrument Type';
            OptionCaption = 'Stock,ETF,Bond,Fund,Cash,Other';
            OptionMembers = Stock,ETF,Bond,Fund,Cash,Other;
        }
        field(100; "Trade Date"; Date)
        {
            Caption = 'Trade Date';
        }
        field(110; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
        }
        field(120; "Tax Year"; Integer)
        {
            Caption = 'Tax Year';
        }
        field(130; ISIN; Code[20])
        {
            Caption = 'ISIN';
        }
        field(140; Ticker; Code[30])
        {
            Caption = 'Ticker';
        }
        field(150; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(160; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(170; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(180; Price; Decimal)
        {
            Caption = 'Price';
        }
        field(190; "Price Currency Code"; Code[10])
        {
            Caption = 'Price Currency Code';
            TableRelation = Currency.Code;
        }
        field(200; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(210; "Gross Amount"; Decimal)
        {
            Caption = 'Gross Amount';
        }
        field(220; "Fee Amount"; Decimal)
        {
            Caption = 'Fee Amount';
        }
        field(230; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
        }
        field(240; "Net Amount"; Decimal)
        {
            Caption = 'Net Amount';
        }
        field(250; "Exchange Rate"; Decimal)
        {
            Caption = 'Exchange Rate';
        }
        field(260; "LCY Gross Amount"; Decimal)
        {
            Caption = 'LCY Gross Amount';
        }
        field(270; "LCY Fee Amount"; Decimal)
        {
            Caption = 'LCY Fee Amount';
        }
        field(280; "LCY Tax Amount"; Decimal)
        {
            Caption = 'LCY Tax Amount';
        }
        field(290; "LCY Net Amount"; Decimal)
        {
            Caption = 'LCY Net Amount';
        }
        field(300; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(310; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(320; "Duplicate Check Key"; Text[250])
        {
            Caption = 'Duplicate Check Key';
        }
        field(330; "Raw Data"; Text[2048])
        {
            Caption = 'Raw Data';
        }
        field(340; "Broker Entry No."; Integer)
        {
            Caption = 'Broker Entry No.';
            TableRelation = "PTE Broker Entry"."Entry No.";
        }
    }

    keys
    {
        key(PK; "Import Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(Status; "Import Entry No.", Status)
        {
        }
        key(DuplicateCheck; "Duplicate Check Key")
        {
        }
    }
}