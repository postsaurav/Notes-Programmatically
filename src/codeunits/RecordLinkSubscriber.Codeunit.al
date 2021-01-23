codeunit 50001 "SDH Record Link Subscriber"
{

    [EventSubscriber(ObjectType::Table, Database::"Record Link", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertRecordLink(var Rec: Record "Record Link"; RunTrigger: Boolean)
    begin
        If not RunTrigger then
            exit;

        If not Rec.Note.HasValue then
            exit;

        InsertRecordLinkIfrequired(Rec);
    end;

    local procedure InsertRecordLinkIfrequired(var RecordLink: Record "Record Link")
    var
        Contact: Record Contact;
        RecList: List of [Text];
    begin
        If (RecordLink."Record ID".TableNo() = 5050) and (RecordLink.Type = RecordLink.Type::Note) then begin
            RecList := Format(RecordLink."Record ID").Split();
            If not Contact.Get(RecList.Get(2)) then
                exit;
            if Contact.Type = Contact.Type::Company then
                exit;
            CreateCompanyNote(RecordLink, Contact);
        end;
    end;

    local procedure CreateCompanyNote(var RecordLink: Record "Record Link"; PersonContact: Record Contact)
    var
        RecordLinkMgmt: Codeunit "Record Link Management";
        PersonContactText: Text;
        CompanyContact: Record Contact;
    begin
        PersonContactText := RecordLinkMgmt.ReadNote(RecordLink);

        IF not CompanyContact.get(PersonContact."Company No.") then
            exit;

        PersonContactText := 'Contact Person ' + PersonContact."First Name" + PersonContact.Surname + ': ' + PersonContactText;
        AddRecordLinkForCompany(RecordLink, CompanyContact, PersonContact, PersonContactText);
    end;

    local procedure AddRecordLinkForCompany(var PersonRecordLink: Record "Record Link"; CompanyContact: Record Contact; PersonContact: Record Contact; PersonContactText: Text)
    var
        CompanyRecordLink: Record "Record Link";
        RecordLinkMgmt: Codeunit "Record Link Management";
    begin
        CompanyRecordLink.Init();
        CompanyRecordLink."Record ID" := CompanyContact.RecordId;
        CompanyRecordLink.Description := PersonRecordLink.Description;
        CompanyRecordLink.Type := CompanyRecordLink.Type::Note;
        CompanyRecordLink.Created := PersonRecordLink.Created;
        CompanyRecordLink."User ID" := PersonRecordLink."User ID";
        CompanyRecordLink.Company := PersonRecordLink.Company;
        RecordLinkMgmt.WriteNote(CompanyRecordLink, PersonContactText);
        CompanyRecordLink.Insert(true);
    end;
}