//
//  ViewController.h
//  Image Effect
//
//  Created by MotionVFX on 18/08/2023.
//

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface ViewController : NSViewController<MTKViewDelegate>


typedef struct
{
    vector_float3 position;
    vector_float4 color;
} Vertex;


@property (nonatomic, strong) MTKView* metalView;
@property (nonatomic, strong) MTKView* metalView2;
@property (nonatomic, strong) id<MTLSamplerState> sampler;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLTexture> texture2;
@property (nonatomic, strong) id<MTLTexture> texture_out;
@property (nonatomic, strong) id<MTLTexture> texture_out2;
@property (nonatomic, strong) MTLRenderPipelineDescriptor* pipelineDescriptor;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) NSData *imageData2;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTLVertexDescriptor* vertexDescriptor;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;


- (IBAction)reset_pushed:(id)sender;
- (IBAction)insert_pushed:(id)sender;
- (IBAction)invokeFunction:(id)sender;
- (void)functionSetter;


@property (weak) IBOutlet NSButton *invokeFunctionButton;
@property (weak) IBOutlet NSComboBox *comboBoxFunctions;
@property (weak) IBOutlet NSTextField *nearest_value3;
@property (weak) IBOutlet NSSlider *nearest_value1;
@property (weak) IBOutlet NSSlider *nearest_value2;
@property (weak) IBOutlet NSComboBox *image_number_choose;
@property (weak) IBOutlet NSTextField *kawase_blur_value;
@property (weak) IBOutlet NSSlider *edge_detection_value;
@property (weak) IBOutlet NSSlider *gamma_grayscale_value;
@property (weak) IBOutlet NSSlider *gamma_value;
@property (weak) IBOutlet NSTextField *button_red;
@property (weak) IBOutlet NSTextField *button_green;
@property (weak) IBOutlet NSTextField *button_blue;
@property (weak) IBOutlet NSTextField *text_chessboard_width;
@property (weak) IBOutlet NSTextField *text_chessboard_height;
@property (weak) IBOutlet NSTextField *interpolation_bicubic_value;
@property (weak) IBOutlet NSTextField *interpolation_linear_value;
@property (weak) IBOutlet NSTextField *time_value_field;

-(void)resizeMetalView;
-(void)resetVertices;
-(void)my_draw:(MTKView *)view;
-(void)setupRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder;
-(MTLSamplerDescriptor*)setupSampler;
-(void)draw_correctly;
-(void)setupPipeline;

@end


