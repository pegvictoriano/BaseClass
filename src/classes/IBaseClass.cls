/**
 * IBaseClass Implementation make sure BaseClass has defined implementation
 */
public interface IBaseClass {
	/**
	 * @description initializes the order of db commit
	 * @param       listCommitOrder [description]
	 */
	void initialize(List<Schema.sObjectType> listCommitOrder);
	/**
	 * @description queues a record for insert / update
	 * @param       sobj            record to create / update
	 * @param       relatedField    field lookup / master-detail
	 * @param       relatedRecord   parent record to relate
	 */
	void push(SObject sobj, Schema.sObjectField relatedField, SObject relatedRecord);
	/**
	 * @description queues a record for delete
	 * @param       sobj            record
	 */
	void pop(SObject sobj);
	/**
	 * @description queue a relationship
	 * @param       sobj            record
	 * @param       relatedField    record field
	 * @param       relatedRecord   parent record
	 */
	void relate(SObject sobj, Schema.sObjectField relatedField, SObject relatedRecord);
	/**
	 * @description returns pre-commit records
	 */
	List<SObject> getRecordsByType(Schema.sObjectType sotType);
	/**
	 * @description perform database transaction rollback on fail
	 * @return      success
	 */
	Boolean commitRecords();
	/**
	 * @description perform database transaction continue and track failed records
	 * @return      failed Error records
	 */
	List<Object> commitRecordsPartial();
}