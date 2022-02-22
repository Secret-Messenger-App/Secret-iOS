#import "TestRelationshipMigration.h"

#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseRelationship.h>

#if PODFILE_USE_FRAMEWORKS
// Works with `use_frameworks`, but not with `use_modular_headers`
#import <YapDatabase/YapDatabaseRelationshipPrivate.h>
#else
// Works with `use_modular_headers`, but not with `use_frameworks`
#import "YapDatabaseRelationshipPrivate.h"
#endif

@implementation TestRelationshipMigration

+ (NSString *)appName
{
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (appName == nil) {
		appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	}
	if (appName == nil) {
		appName = @"YapDatabaseTesting";
	}
	
	return appName;
}

+ (NSURL *)appSupportDir
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray<NSURL*> *urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	NSURL *baseDir = [urls firstObject];
	NSURL *appSupportDir = [baseDir URLByAppendingPathComponent:[self appName] isDirectory:YES];
	
	if (![fileManager fileExistsAtPath:[appSupportDir path]])
	{
		[fileManager createDirectoryAtURL: appSupportDir
		      withIntermediateDirectories: YES
		                       attributes: nil
		                            error: nil];
	}
	
	return appSupportDir;
}

+ (NSURL *)databaseURL
{
	NSString *fileName = @"testRelationshipMigration.sqlite";
	
	return [[self appSupportDir] URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSString *)randomLetters:(NSUInteger)length
{
	NSString *alphabet = @"abcdefghijklmnopqrstuvwxyz";
	NSUInteger alphabetLength = [alphabet length];
	
	NSMutableString *result = [NSMutableString stringWithCapacity:length];
	
	NSUInteger i;
	for (i = 0; i < length; i++)
	{
		unichar c = [alphabet characterAtIndex:(NSUInteger)arc4random_uniform((uint32_t)alphabetLength)];
		
		[result appendFormat:@"%C", c];
	}
	
	return result;
}

+ (NSString *)generateRandomFile
{
	NSString *fileName = [self randomLetters:16];
	
	NSString *appSupportPath = [[self appSupportDir] path];
	NSString *filePath = [appSupportPath stringByAppendingPathComponent:fileName];
	
	// Create the temp file
	[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
	
	return filePath;
}

+ (void)start
{
	NSURL *databaseURL = [self databaseURL];
	NSLog(@"databaseURL: %@", [databaseURL path]);
	
//	[[NSFileManager defaultManager] removeItemAtPath:databaseFilePath error:NULL];
	
	YapDatabase *database = [[YapDatabase alloc] initWithURL:databaseURL];
	YapDatabaseConnection *connection = [database newConnection];
	
	NSString *rowA = @"a";
	NSString *rowB = @"b";
	NSString *rowC = @"c";
	NSString *rowD = @"d";
	
	#pragma unused(rowA)
	#pragma unused(rowB)
	#pragma unused(rowC)
	#pragma unused(rowD)
	
#if YAP_DATABASE_RELATIONSHIP_CLASS_VERSION < 4
	
	NSString *filePathC = [self generateRandomFile];
	NSString *filePathD = [self generateRandomFile];
	
#endif
	
	// rowA -> rowB
	// rowC -> fileC (fileC path stored unencrypted, as string)
	// rowD -> fileD (fileD path stored "encrypted", as blob)
	
	YapDatabaseRelationshipOptions *options = [[YapDatabaseRelationshipOptions alloc] init];
	
#if YAP_DATABASE_RELATIONSHIP_CLASS_VERSION < 4
	
	options.destinationFilePathEncryptor = ^NSData* (NSString *dstFilePath){
		
		// We only encrypt filePathD
		
		if ([dstFilePath isEqualToString:filePathC])
			return nil;
		else
			return [dstFilePath dataUsingEncoding:NSUTF8StringEncoding];
	};
	
	options.destinationFilePathDecryptor = ^id (NSData *data){
		
		return [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
	};
#else
	
	YapDatabaseRelationshipMigration defaultMigration = [YapDatabaseRelationshipOptions defaultMigration];
	
	options.migration = ^NSURL* (NSString *filePath, NSData *data) {
		
		if (data) {
			filePath = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
		}
		
		return defaultMigration(filePath, nil);
	};
	
#endif
	
	YapDatabaseRelationship *relationship = [[YapDatabaseRelationship alloc] initWithVersionTag:nil options:options];
	NSString *extName = @"relationship";
	
	BOOL result = [database registerExtension:relationship withName:extName];
	if (!result)
	{
		NSLog(@"Oops !");
		return;
	}
	
#if YAP_DATABASE_RELATIONSHIP_CLASS_VERSION < 4
	
	[connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:rowA forKey:rowA inCollection:nil];
		[transaction setObject:rowB forKey:rowB inCollection:nil];
		[transaction setObject:rowC forKey:rowC inCollection:nil];
		[transaction setObject:rowD forKey:rowD inCollection:nil];
		
		YapDatabaseRelationshipEdge *edgeAB =
		  [YapDatabaseRelationshipEdge edgeWithName:@"child"
		                                  sourceKey:rowA
		                                 collection:nil
		                             destinationKey:rowB
		                                 collection:nil
		                            nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted];
		
		YapDatabaseRelationshipEdge *edgeC =
		  [YapDatabaseRelationshipEdge edgeWithName:@"child"
		                                  sourceKey:rowC
		                                 collection:nil
		                        destinationFilePath:filePathC
		                            nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted];
		
		YapDatabaseRelationshipEdge *edgeD =
		  [YapDatabaseRelationshipEdge edgeWithName:@"child"
		                                  sourceKey:rowD
		                                 collection:nil
		                        destinationFilePath:filePathD
		                            nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted];
		
		[[transaction ext:extName] addEdge:edgeAB];
		[[transaction ext:extName] addEdge:edgeC];
		[[transaction ext:extName] addEdge:edgeD];
	}];
	
#endif
	
	[connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		[[transaction ext:extName] enumerateEdgesWithName:@"child"
		                                       usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
		{
			NSLog(@"edge: %@", edge);
		}];
	}];
}

@end
