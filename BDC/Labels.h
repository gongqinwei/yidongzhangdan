//
//  Labels.h
//  BDC
//
//  Created by Qinwei Gong on 3/3/13.
//
//

#import "Util.h"

#ifndef BDC_Labels_h
#define BDC_Labels_h

// for UIRefreshControl
#define PULL_TO_REFRESH         [[NSAttributedString alloc] initWithString:@"Pull to Refresh"]
#define REFRESHING              [[NSAttributedString alloc] initWithString:@"Refreshing Data..."]
#define LAST_REFRESHED          [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last Updated on %@", [Util formatDate:[NSDate date] format:@"MMM d, h:mm a"]]]

#endif
