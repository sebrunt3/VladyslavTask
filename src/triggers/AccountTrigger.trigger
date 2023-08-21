trigger AccountTrigger on Account (before delete, after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountOwnersSharingHandler.afterInsertSharingOwners(Trigger.newMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountOwnersSharingHandler.afterUpdateSharingOwners(Trigger.newMap, Trigger.oldMap);
    }
    
    if (Trigger.isBefore && Trigger.isDelete) {
        AccountOwnersSharingHandler.beforeDeleteSharingOwners(Trigger.oldMap);
    }
}