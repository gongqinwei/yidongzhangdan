//
//  Organization.m
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Organization.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "UIHelper.h"


@implementation Organization

static id <OrgDelegate> delegate = nil;
static NSArray *orgs = nil;
static Organization *selectedOrg = nil;

+ (id<OrgDelegate>)getDelegate {
    return delegate;
}

+ (void)setDelegate:(id<OrgDelegate>)theDelegate {
    delegate = theDelegate;
}

+ (id)list {
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    orgs = [orgs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]];
    
    return orgs;
}

+ (void)setOrgs:(NSArray *)orgList {
    orgs = orgList;
}

+ (Organization *)getSelectedOrg {
    return selectedOrg;
}

+ (void)selectOrg:(Organization *)org {
    selectedOrg = org;
    
    // persist
    [Util setSelectedOrgId:org.objectId];
}

+ (void)retrieveList {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
    [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
    
    [APIHandler asyncCallWithAction:LIST_ORG_API Info:info AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        
        NSArray *jsonOrgs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        if(response_status == RESPONSE_SUCCESS) {
            if ([jsonOrgs count] > 0) {
                NSMutableArray *orgArr = [[NSMutableArray alloc] init];

                for (int i = 0; i < [jsonOrgs count]; i++) {
                    NSDictionary *dict = (NSDictionary*)[jsonOrgs objectAtIndex:i];
                    Organization *org = [[Organization alloc] init];
                    org.objectId = [dict objectForKey:@"orgId"];
                    org.name = [dict objectForKey:@"orgName"];
                    [orgArr addObject:org];
                    
                    NSString *selectedOrgId = [Util getSelectedOrgId];
                    if (selectedOrgId != nil && [selectedOrgId length] > 0 && [selectedOrgId isEqualToString:org.objectId]) {
                        [Organization selectOrg:org];
                    }
                }
                
                NSArray *orgs = [NSArray arrayWithArray:orgArr];
                [Organization setOrgs:orgs];                
                
                [delegate didGetOrgs:orgs status:kSucceedLogin];
            } else {
                [delegate didGetOrgs:nil status:kFailListOrgs];
            }
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            [delegate didGetOrgs:nil status:kFailLogin];
        }
    }];
}

@end
