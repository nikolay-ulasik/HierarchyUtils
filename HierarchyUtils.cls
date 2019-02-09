public without sharing class HierarchyUtils {

    public class HierarchyUtilsException extends Exception {
    }

    private static Map<SObjectType, HierarchyUtils> utilsInstanceMap = new Map<SObjectType, HierarchyUtils>();

    public static HierarchyUtils getInstance(SObjectType sObjType, SObjectField parentSObjectField) {
        HierarchyUtils result;
        if (sObjType != null && parentSObjectField != null) {
            if (!sObjType.getDescribe().isAccessible()) {
                throw new HierarchyUtilsException('Passed object is not accessible');
            }
            if (!parentSObjectField.getDescribe().isAccessible()) {
                throw new HierarchyUtilsException('Passed field is not accessible');
            }
            if (utilsInstanceMap.containsKey(sObjType)) {
                result = utilsInstanceMap.get(sObjType);
            } else {
                result = new HierarchyUtils(sObjType, parentSObjectField);
                utilsInstanceMap.put(sObjType, result);
            }

        }
        return result;
    }

    private SObjectType sObjType;
    private SObjectField parentSObjectField;

    private List<SObject> hierarchyItems {
        get {
            return (hierarchyItems == null) ? (hierarchyItems = getHierarchyItems()) : hierarchyItems;
        }
        set;
    }

    private Map<Id, Set<Id>> hierarchyByLevel {
        get {
            return (hierarchyByLevel == null) ? (hierarchyByLevel = getHierarchyByLevel()) : hierarchyByLevel;
        }
        set;
    }

    private Map<Id, Id> recordIdParentId {
        get {
            return (recordIdParentId == null) ? (recordIdParentId = getRecordIdParentId()) : recordIdParentId;
        }
        set;
    }

    private HierarchyUtils() {
    }

    private HierarchyUtils(SObjectType sObjType, SObjectField parentSObjectField) {
        this.sObjType = sObjType;
        this.parentSObjectField = parentSObjectField;
    }

    private List<SObject> getHierarchyItems() {
        return Database.query(
                String.format(
                        'SELECT {0} FROM {1} LIMIT 50000',
                        new List<String>{
                                String.join(
                                        new List<String>{
                                                'Id',
                                                parentSObjectField.getDescribe().getName()
                                        },
                                        ','
                                ),
                                sObjType.getDescribe().getName()
                        }
                )
        );
    }

    private Map<Id, Id> getRecordIdParentId() {
        Map<Id, Id> result = new Map<Id, Id>();

        Id recordId;
        Id parentId;

        for (SObject hierarchyItem : hierarchyItems) {

            recordId = (Id) hierarchyItem.get('Id');
            parentId = (Id) hierarchyItem.get(parentSObjectField.getDescribe().getName());

            if (parentId != null) {
                result.put(recordId, parentId);
            }
        }

        return result;
    }

    private Map<Id, Set<Id>> getHierarchyByLevel() {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        Id recordId;
        Id parentId;
        Set<Id> childIds;

        for (SObject hierarchyItem : hierarchyItems) {

            recordId = (Id) hierarchyItem.get('Id');
            parentId = (Id) hierarchyItem.get(parentSObjectField.getDescribe().getName());

            if (!result.containsKey(recordId)) {
                result.put(recordId, new Set<Id>());
            }

            if (parentId != null) {
                childIds = result.get(parentId);

                if (childIds == null) {
                    result.put(parentId, childIds = new Set<Id>());
                }
                childIds.add(recordId);
            }
        }

        return result;
    }

    public List<Id> getPathUp(Id recordId) {
        List<Id> result = new List<Id>();
        fillPathUp(recordIdParentId.get(recordId), result);
        return result;
    }

    public Map<Id, List<Id>> getPathUp(List<Id> recordIds) {
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();

        for (Id recordId : recordIds) {
            result.put(recordId, getPathUp(recordId));
        }

        return result;
    }

    public List<Id> getAllChildIds(Id recordId) {
        List<Id> result = new List<Id>();
        fillChildIds(hierarchyByLevel.get(recordId), result);
        return result;
    }

    public Map<Id, List<Id>> getAllChildIds(List<Id> recordIds) {
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();

        for (Id recordId : recordIds) {
            result.put(recordId, getAllChildIds(recordId));
        }

        return result;
    }

    public void clear() {
        hierarchyItems = null;
        hierarchyByLevel = null;
        recordIdParentId = null;
    }

    private void fillPathUp(Id parentId, List<Id> result) {
        if (parentId != null) {
            result.add(parentId);
            fillPathUp(recordIdParentId.get(parentId), result);
        }
    }

    private void fillChildIds(Set<Id> childIds, List<Id> result) {
        if (childIds != null && !childIds.isEmpty()) {
            result.addAll(childIds);
            for (Id childId : childIds) {
                fillChildIds(hierarchyByLevel.get(childId), result);
            }
        }
    }

}