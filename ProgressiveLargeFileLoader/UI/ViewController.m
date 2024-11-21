//
//  ViewController.m
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import "ViewController.h"
#import "Presenter.h"

@interface ViewController ()<PresenterDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) IBOutlet UITextField* urlTextField;
@property(nonatomic, weak) IBOutlet UITextField* maskTextField;
@property(nonatomic, weak) IBOutlet UIButton* loadButton;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicatorView;
@property(nonatomic, weak) IBOutlet UITableView* tableView;

@property(nonatomic, strong) Presenter* presenter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.presenter = [[Presenter alloc] initWithDelegate:self];
#if DEBUG
    self.urlTextField.text = @"https://www.gutenberg.org/files/100/100-0.txt";
    self.maskTextField.text = @"*THE*";
#endif
}

- (IBAction)loadButtonTapped:(id)sender {
    NSString* urlText = self.urlTextField.text;
    if(urlText.length == 0) {
        return;
    }
    [self.tableView setContentOffset:CGPointZero animated:YES];
    NSURL* url = [NSURL URLWithString:urlText];
    NSString* mask = self.maskTextField.text;
    [self.view endEditing:YES];
    [self updateLoadingState:YES];
    [self.presenter load:url mask:mask];
}

- (void)updateLoadingState:(BOOL)loading {
    self.loadButton.enabled = !loading;
    self.urlTextField.enabled = !loading;
    self.maskTextField.enabled = !loading;
    
    if(loading) {
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView stopAnimating];
    }
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.presenter numberOfStrings];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [self.presenter stringForIndex:indexPath.row];
    return cell;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)maskTextFieldDidChangeText:(UITextField*)textField {
    self.loadButton.enabled = self.maskTextField.text.length > 0 && self.urlTextField.text.length > 0;
}

// MARK: - PresenterDelegate

- (void)presenterDidUpdateLoadedStrings:(Presenter*)presenter {
    [self.tableView reloadData];
}
- (void)presenterDidFinishLoading:(Presenter*)presenter {
    [self.tableView reloadData];
    [self updateLoadingState:NO];
}

@end
