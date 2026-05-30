enum 50103 "PTE Broker Import Line Status"
{
    Caption = 'Broker Import Line Status';

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Valid)
    {
        Caption = 'Valid';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(3; Imported)
    {
        Caption = 'Imported';
    }
    value(4; Skipped)
    {
        Caption = 'Skipped';
    }
}