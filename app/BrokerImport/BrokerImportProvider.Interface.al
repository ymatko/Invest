interface "PTE Broker Report Provider"
{
    procedure Import(Broker: Record "PTE Broker"; SourceFileName: Text; var SourceInStream: InStream; var ImportHeader: Record "PTE Broker Import Header");
}