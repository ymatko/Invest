enum 50103 "PTE Broker Import Line Status"
{
    Caption = 'Broker Import Line Status', Locked = true;

    value(0; New)
    {
        Caption = 'New', Locked = true;
    }
    value(1; Valid)
    {
        Caption = 'Valid', Locked = true;
    }
    value(2; Error)
    {
        Caption = 'Error', Locked = true;
    }
    value(3; Imported)
    {
        Caption = 'Imported', Locked = true;
    }
    value(4; Skipped)
    {
        Caption = 'Skipped', Locked = true;
    }
}