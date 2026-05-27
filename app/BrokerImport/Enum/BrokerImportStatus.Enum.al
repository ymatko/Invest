enum 50102 "PTE Broker Import Status"
{
    Caption = 'Broker Import Status', Locked = true;

    value(0; Created)
    {
        Caption = 'Created', Locked = true;
    }
    value(1; Validated)
    {
        Caption = 'Validated', Locked = true;
    }
    value(2; Imported)
    {
        Caption = 'Imported', Locked = true;
    }
    value(3; Failed)
    {
        Caption = 'Failed', Locked = true;
    }
    value(4; PartiallyImported)
    {
        Caption = 'Partially Imported', Locked = true;
    }
}