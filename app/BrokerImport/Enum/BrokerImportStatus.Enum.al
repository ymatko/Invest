enum 50102 "PTE Broker Import Status"
{
    Caption = 'Broker Import Status';

    value(0; Created)
    {
        Caption = 'Created';
    }
    value(1; Validated)
    {
        Caption = 'Validated';
    }
    value(2; Imported)
    {
        Caption = 'Imported';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
    value(4; PartiallyImported)
    {
        Caption = 'Partially Imported';
    }
}