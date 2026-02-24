trigger ContentVersionTrigger on ContentVersion (after insert) {
    if(trigger.isinsert && trigger.isafter){
        
        list<ContentDocumentLink> contentDocumentLinkList = new list<ContentDocumentLink>();
        string userId = [select id,name from user where name = 'Team Legal'].id;
        for(ContentVersion conVersion : trigger.new){
            ContentDocumentLink conLink = new ContentDocumentLink();
            conLink.ContentDocumentId = conVersion.ContentDocumentId;
            conLink.LinkedEntityId = userId;
            conLink.ShareType = 'C';
            conLink.Visibility = 'AllUsers';
            contentDocumentLinkList.add(conLink);
        }
        system.debug('contentDocumentLinkList:::'+contentDocumentLinkList);
        insert contentDocumentLinkList;
    }
}