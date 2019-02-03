public without sharing class HierarchyUtils {

    private static Map<String, HierarchyUtils> utilsInstanceMap = new Map<String, HierarchyUtils>();

    public static HierarchyUtils getInstance(String sObjectName, String parentIdFieldName) {
        HierarchyUtils result;
        if (String.isNotBlank(sObjectName) && String.isNotBlank(parentIdFieldName)) {
            if (utilsInstanceMap.containsKey(sObjectName)) {
                result = utilsInstanceMap.get(sObjectName);
            } else {
                result = new HierarchyUtils(sObjectName, parentIdFieldName);
                utilsInstanceMap.put(sObjectName, result);
            }
        }
        return result;
    }

    private String sObjectName;
    private String parentIdFieldName;

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

    private HierarchyUtils(String sObjectName, String parentIdFieldName) {
        this.sObjectName = sObjectName;
        this.parentIdFieldName = parentIdFieldName;
    }

    private List<SObject> getHierarchyItems() {
        String queryTemplate = 'SELECT {0} FROM {1} LIMIT 50000';
        List<String> queryParameters = new List<String>{
                String.join(new List<String>{
                        'Id', parentIdFieldName
                }, ','),
                sObjectName
        };
        return Database.query(String.format(queryTemplate, queryParameters));
    }

    private Map<Id, Id> getRecordIdParentId() {
        Map<Id, Id> result = new Map<Id, Id>();

        Id recordId;
        Id parentId;

        for (SObject hierarchyItem : hierarchyItems) {

            recordId = (Id) hierarchyItem.get('Id');
            parentId = (Id) hierarchyItem.get(parentIdFieldName);

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
            parentId = (Id) hierarchyItem.get(parentIdFieldName);

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