//
// ShowsViewController.m
//
// Copyright (c) 2015 Bogdan Kovachev (http://1337.bg)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "ShowsViewController.h"
#import "ShowViewController.h"

@interface ShowsViewController () {
    // User interface
    __weak IBOutlet UITableView *showsTableView;

    // Other
    NSArray *shows;
    NSDictionary *searchedShow;
}

@end

@implementation ShowsViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Populate the TV shows
    shows = @[@{@"id": @1, @"title": @"Mr. Robot", @"year": @2015, @"genre": @"Crime, Drama"},
              @{@"id": @2, @"title": @"Better Call Saul", @"year": @2015, @"genre": @"Crime, Drama"},
              @{@"id": @3, @"title": @"True Detective", @"year": @2014, @"genre": @"Crime, Drama, Mystery"},
              @{@"id": @4, @"title": @"Breaking Bad", @"year": @2008, @"genre": @"Crime, Drama, Thriller"},
              @{@"id": @5, @"title": @"Archer", @"year": @2009, @"genre": @"Animation, Action, Comedy"}];

    // Delete old searchable items
    [self deleteAllSearchableItems];

    // Get all the searchable TV shows
    NSArray *items = [self searchableShows];

    // Get all the searchable screens
    NSArray *screen = [self searchableScreens];

    // Make both TV shows and screens searchable
    [self indexSearchableItems:[items arrayByAddingObjectsFromArray:screen]];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowSegue"]) {
        ShowViewController *targetVC = segue.destinationViewController;

        NSDictionary *show = (searchedShow) ? searchedShow : [self showAtIndexPath:[showsTableView indexPathForSelectedRow]];
        targetVC.show = show;
    }
}

#pragma mark - Actions

- (NSDictionary *)showAtIndexPath:(NSIndexPath *)indexPath {
    return shows[indexPath.row];
}

- (NSDictionary *)showWithIdentifier:(NSString *)identifier {
    for (NSDictionary *show in shows) {
        if ([identifier isEqualToString:[show[@"id"] stringValue]]) {
            return show;
        }
    }

    return nil;
}

#pragma mark - Search related

- (NSArray *)searchableShows {
    NSMutableArray *searchableItems = [NSMutableArray array];

    for (NSDictionary *show in shows) {
        CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];

        attributeSet.title = show[@"title"];
        attributeSet.contentDescription = [NSString stringWithFormat:@"%@\n%@", show[@"genre"], show[@"year"]];

        NSMutableArray *keywords = [NSMutableArray array];
        [keywords addObjectsFromArray:[show[@"title"] componentsSeparatedByString:@" "]];
        [keywords addObjectsFromArray:[show[@"genre"] componentsSeparatedByString:@", "]];
        [keywords addObject:show[@"year"]];
        attributeSet.keywords = keywords;

        CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[show[@"id"] stringValue]
                                                                   domainIdentifier:@"shows"
                                                                       attributeSet:attributeSet];

        [searchableItems addObject:item];
    }

    return searchableItems;
}

- (NSArray *)searchableScreens {
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];

    attributeSet.title = @"TV Shows";
    attributeSet.contentDescription = @"List all the TV shows";
    attributeSet.keywords = @[@"TV", @"show"];

    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:@"tv-shows"
                                                               domainIdentifier:@"functionality"
                                                                   attributeSet:attributeSet];

    return @[item];
}

- (void)deleteAllSearchableItems {
    [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error while deleting: %@", error.localizedDescription);
        }
    }];
}

- (void)indexSearchableItems:(NSArray *)searchableItems {
    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchableItems completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error while indexing: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return shows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ShowCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSDictionary *show = [self showAtIndexPath:indexPath];
    cell.textLabel.text = show[@"title"];

    return cell;
}

#pragma mark - Deep linking

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    searchedShow = [self showWithIdentifier:activity.userInfo[@"kCSSearchableItemActivityIdentifier"]];

    if (searchedShow) {
        [self performSegueWithIdentifier:@"ShowSegue" sender:self];
    }
}

@end