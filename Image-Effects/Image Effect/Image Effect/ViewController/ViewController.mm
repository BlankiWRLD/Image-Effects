//
//  ViewController.m
//  Image Effect
//
//  Created by MotionVFX on 18/08/2023.
//

#import "ViewController.h"

#include <chrono>
#include <string>

@implementation ViewController

NSInteger numVertices = 0;
NSInteger field_to_fill_type = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.device = MTLCreateSystemDefaultDevice();
    [self setupMetalViews];
    [self setupPipeline];
    [self setupComboBoxFunctions];
    [self.image_number_choose addItemWithObjectValue:@"Image 1"];
    [self.image_number_choose addItemWithObjectValue:@"Image 2"];
    [self.image_number_choose selectItemAtIndex:0];
}
- (void)setupMetalViews {
    self.metalView = [self createMetalViewWithFrame:CGRectMake(10, 10, 560, 560)];
    self.metalView2 = [self createMetalViewWithFrame:CGRectMake(930, 10, 560, 560)];
    
    [self.view addSubview:self.metalView];
    [self.view addSubview:self.metalView2];
}
- (MTKView *)createMetalViewWithFrame:(CGRect)frame {
    MTKView *metalView = [[MTKView alloc] initWithFrame:frame device:self.device];
    metalView.delegate = self;
    metalView.clearColor = MTLClearColorMake(30./255., 20./255., 45./255., 1.);
    return metalView;
}
- (void)setupComboBoxFunctions {
    NSArray *functionTitles = @[@"One triangle render", @"Two triangle render",@"Multiple triangle render", @"Chessboard",@"Negative",  @"Grayscale",@"Grayscale + Negative", @"Gamma correction",@"Grayscale + Gamma", @"Mix: Chessboard + Image", @"Edge detection", @"Lut", @"Negative + Lut", @"Blur 1", @"Blur 2", @"Blur Kawase", @"Interpolation - Nearest", @"Interpolation - Bicubic", @"Interpolation - Linear", @"Effect difference"];
    
    for (NSString *title in functionTitles) {
        [self.comboBoxFunctions addItemWithObjectValue:title];
    }
    [self.comboBoxFunctions selectItemAtIndex:0];
    [self.comboBoxFunctions setNumberOfVisibleItems:10];
}
- (void)setupDefaultValues {
    self.texture_out = nil;
    self.texture = nil;
    self.texture2 = nil;
    self.texture_out2 = nil;
    field_to_fill_type = 0;
    [self.gamma_value setDoubleValue:.0];
    [self.gamma_grayscale_value setDoubleValue:.0];
    [self.edge_detection_value setDoubleValue:.0];
    [self.button_red setMaximumNumberOfLines:10];
    [self.button_green setMaximumNumberOfLines:10];
    [self.button_blue setMaximumNumberOfLines:10];
    [self.text_chessboard_width setMaximumNumberOfLines:10];
    [self.text_chessboard_height setMaximumNumberOfLines:10];
    [self.kawase_blur_value setDoubleValue:3];
    [self.interpolation_linear_value setDoubleValue:3];
    [self.interpolation_bicubic_value setDoubleValue:3];
}
- (void)setupUIElements {
    NSArray *uiElements = @[
        self.gamma_value, self.gamma_grayscale_value, self.edge_detection_value,
        self.button_red, self.button_green, self.button_blue,
        self.text_chessboard_width, self.text_chessboard_height,
        self.kawase_blur_value, self.interpolation_linear_value, self.interpolation_bicubic_value
    ];
    
    for (id element in uiElements) {
        if ([element respondsToSelector:@selector(setDoubleValue:)]) {
            [element setDoubleValue:0.];
        } else if ([element respondsToSelector:@selector(setMaximumNumberOfLines:)]) {
            [element setMaximumNumberOfLines:10];
        } else if ([element respondsToSelector:@selector(setHidden:)]) {
            [element setHidden:YES];
        }
    }
}


- (id<MTLTexture>)createAndInitializeTextureWithWidth:(NSUInteger)width
                                              height:(NSUInteger)height
                                               usage:(MTLTextureUsage)usage{
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage = usage;

    return [self.device newTextureWithDescriptor:textureDescriptor];
}

- (BOOL)isImage1
{
    return [[self.image_number_choose stringValue] isEqualToString:@"Image 1"];
}

- (BOOL)isEqToString:(NSString*)str
{
    return [[self.comboBoxFunctions stringValue] isEqualToString:str];
}

-(void)setPipeline:(NSString*)vertex
            string:(NSString*)fragment
{
    NSError* error = nil;
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:vertex];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:fragment];
    _pipelineDescriptor.fragmentFunction = fragmentFunction;
    _pipelineDescriptor.vertexFunction = vertexFunction;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&error];
}

-(void)setupPipeline {
    NSError* error = nil;
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    
    _pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    _pipelineDescriptor.vertexFunction = vertexFunction;
    _pipelineDescriptor.fragmentFunction = fragmentFunction;
    _pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&error];
    if(!self.pipelineState) NSLog(@"Failed to create pipeline state: %@", error);
}

- (void)draw_correctly
{
    [self my_draw:[self isImage1] ? self.metalView : self.metalView2];
}



-(void)drawInMTKView:(MTKView *)view {}


-(MTLSamplerDescriptor*)setupSampler
{
    MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
    return samplerDescriptor;
}

-(void)setupRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setRenderPipelineState:self.pipelineState];
    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderEncoder setFragmentSamplerState:self.sampler atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:numVertices];
}


-(void)my_draw:(MTKView *)view
{
    auto start = std::chrono::steady_clock::now();
    
    id<MTLCommandBuffer> commandBuffer = [self.device newCommandQueue].commandBuffer;
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    

    bool is_image1 = [self isImage1];
    
    if(renderPassDescriptor!=nil && numVertices!=0)
    {

        self.sampler = [self.device newSamplerStateWithDescriptor:[self setupSampler]];
        
#pragma mark NOTHING
        if(field_to_fill_type==0){
            [self setPipeline:@"vertex_main" string:@"fragment_main_black"];
            
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [self setupRenderEncoder:renderEncoder];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
        }
        
#pragma mark BASIC TRIANGLE
        else if((field_to_fill_type==1 || field_to_fill_type==2 || field_to_fill_type==3)){
            [self setPipeline:@"vertex_main" string:@"fragment_main"];
            
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [self setupRenderEncoder:renderEncoder];
            
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
        }

#pragma mark BASIC CHESSBOARD
        else if(field_to_fill_type==4)
        {
            [self setPipeline:@"vertex_main_basic" string:@"fragment_main_chessboard"];
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            
            if(is_image1)
                [renderEncoder setFragmentTexture:self.texture atIndex:0];
            else
                [renderEncoder setFragmentTexture:self.texture2 atIndex:0];
            
            float width = [self.text_chessboard_width doubleValue];
            float height = [self.text_chessboard_height doubleValue];
            float data[2] = {width, height};
            id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:data length:sizeof(double[2]) options:MTLResourceStorageModeShared];
            [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            
            [self setupRenderEncoder:renderEncoder];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
        }
        
#pragma mark BASE TEXTURE
        else if(field_to_fill_type==5)
        {
            [self setPipeline:@"vertex_main_basic" string:@"fragment_main_basic"];
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            if(is_image1)
                [renderEncoder setFragmentTexture:self.texture_out atIndex:0];
            else
                [renderEncoder setFragmentTexture:self.texture_out2 atIndex:0];
            
            [self setupRenderEncoder:renderEncoder];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
            
        }
        
#pragma mark GRAYSCALE, BLURS, GAMMA, LUT, NEGATIVE, BICUBIC AND LINEAR INNTERPOLATION AND EFFECT DIFFERENCE
        else if((field_to_fill_type >=6 && field_to_fill_type<=13) || field_to_fill_type==20 || field_to_fill_type==21 || field_to_fill_type==16)
        {
            [self setPipeline:@"vertex_main_basic" string:@"fragment_main_basic"];
            NSInteger width, height;
            
            if(is_image1)
            {width = self.texture.width; height = self.texture.height;}
            else
            {width = self.texture2.width; height = self.texture2.height;}
            
            id<MTLTexture> outputTexture = [self createAndInitializeTextureWithWidth:width height:height usage:MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget];
            id<MTLTexture> inputTexture = [self createAndInitializeTextureWithWidth:width height:height usage:MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget];
            
            NSError *error = nil;
            id<MTLLibrary> library = [self.device newDefaultLibrary];
            id<MTLFunction> kernelFunction;
            
            NSDictionary *kernelFunctionMapping = @{
                @(6): @"kernel_grayscale",
                @(7): @"kernel_blur",
                @(8): @"kernel_blur",
                @(9): @"kernel_kawase_blur",
                @(10): @"kernel_gamma",
                @(11): @"kernel_lut",
                @(12): @"kernel_negative",
                @(13): @"kernel_grayscale_negative",
                @(16): @"kernel_effect_difference",
                @(20): @"kernel_bicubic_interpolation",
                @(21): @"kernel_linear_interpolation"
            };

            NSString *kernelFunctionName = kernelFunctionMapping[@(field_to_fill_type)];

            if (kernelFunctionName) {
                kernelFunction = [library newFunctionWithName:kernelFunctionName];
            }

            
            std::vector<int *> blurRadii;
            int i;
            if(field_to_fill_type == 9) i = static_cast<int>([self.kawase_blur_value doubleValue]);
            else if(field_to_fill_type == 21) i = static_cast<int>([self.interpolation_linear_value doubleValue]);
            else i = static_cast<int>([self.interpolation_bicubic_value doubleValue]);
            
            for(int j=2; j<=i; j++) blurRadii.push_back(&j);
            
            self.computePipelineState = [self.device newComputePipelineStateWithFunction:kernelFunction error:&error];
            
            id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
            [computeEncoder setComputePipelineState:self.computePipelineState];
            
            
            
            if(field_to_fill_type==16)
            {
                if(is_image1)
                {
                    [computeEncoder setTexture:self.texture_out2 atIndex:0];
                    [computeEncoder setTexture:self.texture_out atIndex:1];
                    [computeEncoder setTexture:inputTexture atIndex:2];
                }
                    
                else
                {
                    [computeEncoder setTexture:self.texture_out2 atIndex:1];
                    [computeEncoder setTexture:self.texture_out atIndex:0];
                    [computeEncoder setTexture:inputTexture atIndex:2];
                }
            }
            else
            {
                if(is_image1)
                    [computeEncoder setTexture:self.texture_out atIndex:0];
                else
                    [computeEncoder setTexture:self.texture_out2 atIndex:0];
                [computeEncoder setTexture:inputTexture atIndex:1];
            }
            
            
            
            
            MTLSize threadGroupSize = MTLSizeMake(16, 16, 1);
            MTLSize threadGroups;
            
            if(field_to_fill_type==4)
            {
                float width = [self.text_chessboard_width doubleValue];
                float height = [self.text_chessboard_height doubleValue];
                float data[2] = {width, height};
                [computeEncoder setBytes:data length:sizeof(float[2]) atIndex:0];
            }
            
            if(field_to_fill_type==9 || field_to_fill_type==20 || field_to_fill_type==21)
            {
                float e = 1;
                [computeEncoder setBytes:&e length:sizeof(float) atIndex:0];
            }
            
                
                
                if(field_to_fill_type==10)
                {
                    float e = [self.gamma_value floatValue];
                    [computeEncoder setBytes:&e length:sizeof(float) atIndex:0];
                }
                
                if(field_to_fill_type==11)
                {
                    float a=[self.button_red floatValue]/static_cast<float>(100.), b=[self.button_green floatValue]/static_cast<float>(100.), c=[self.button_blue floatValue]/static_cast<float>(100.);
                    
                    float e[3] = {a,c,b};
                    [computeEncoder setBytes:&e length:sizeof(float[3]) atIndex:0];
                }
                
                
                
                if(is_image1)
                    threadGroups = MTLSizeMake(self.texture.width / threadGroupSize.width, self.texture.height / threadGroupSize.height, 1);
                else
                    threadGroups = MTLSizeMake(self.texture2.width / threadGroupSize.width, self.texture2.height / threadGroupSize.height, 1);
                
                [computeEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
                [computeEncoder endEncoding];
            
               outputTexture = inputTexture;
                
            if(field_to_fill_type==9 || field_to_fill_type==20 || field_to_fill_type==21)
                if(i>=2)
                {
                    for (auto radiusValue: blurRadii) {
                        
                        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
                        [computeEncoder setComputePipelineState:self.computePipelineState];
                        
                        float blurRadius = static_cast<float>(*radiusValue);
                        [computeEncoder setBytes:&blurRadius length:sizeof(float) atIndex:0];
                        
                        [computeEncoder setTexture:inputTexture atIndex:0];
                        [computeEncoder setTexture:outputTexture atIndex:1];
                        
                        MTLSize threadGroupSize = MTLSizeMake(16, 16, 1);
                        MTLSize threadGroups;
                        
                        if(is_image1)
                            threadGroups = MTLSizeMake(self.texture.width / threadGroupSize.width, self.texture.height / threadGroupSize.height, 1);
                        else
                            threadGroups = MTLSizeMake(self.texture2.width / threadGroupSize.width, self.texture2.height / threadGroupSize.height, 1);
                        
                        [computeEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
                        [computeEncoder endEncoding];
                        inputTexture = outputTexture;
                        
                    }
                }
            
            if(field_to_fill_type==8)
            {
                id<MTLComputeCommandEncoder> computeEncoder2 = [commandBuffer computeCommandEncoder];
                [computeEncoder2 setComputePipelineState:self.computePipelineState];
                [computeEncoder2 setTexture:inputTexture atIndex:0];
                [computeEncoder2 setTexture:outputTexture atIndex:1];
                [computeEncoder2 dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
                [computeEncoder2 endEncoding];
            }
                
                id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                
                if(is_image1)
                {
                    self.texture_out = outputTexture;
                    [renderEncoder setFragmentTexture:self.texture_out atIndex:0];
                }
                
                else
                {
                    self.texture_out2 = outputTexture;
                    [renderEncoder setFragmentTexture:self.texture_out2 atIndex:0];
                }
                
                [self setupRenderEncoder:renderEncoder];
                [renderEncoder endEncoding];
                [commandBuffer presentDrawable:view.currentDrawable];
                
                [commandBuffer commit];
                [commandBuffer waitUntilCompleted];
            }
        
        else
        {
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            
#pragma mark IMAGE+CHESSBOARD
            if(field_to_fill_type==14)
            {
                [self setPipeline:@"vertex_main_basic" string:@"fragment_main_chessboard_image"];
                float xpipi1 = [self.text_chessboard_width doubleValue];
                float xpipi2 = [self.text_chessboard_height doubleValue];
                float xpipi[2] = {xpipi1, xpipi2};
                id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:xpipi length:sizeof(double[2]) options:MTLResourceStorageModeShared];
                [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            }
#pragma mark EDGE DETECTION
            else if(field_to_fill_type==15)
            {
                [self setPipeline:@"vertex_main_basic" string:@"fragment_main_edge_detection"];
                float xpipi = [self.edge_detection_value doubleValue];
                id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:&xpipi length:sizeof(double) options:MTLResourceStorageModeShared];
                [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            }

#pragma mark GRAYSCALE + GAMMA
            else if(field_to_fill_type==17)
            {
                [self setPipeline:@"vertex_main_basic" string:@"fragment_main_grayscale_gamma"];
                float xpipi = [self.gamma_grayscale_value doubleValue];
                id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:&xpipi length:sizeof(double) options:MTLResourceStorageModeShared];
                [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            }
#pragma mark NEGATIVE + LUT
            else if(field_to_fill_type==18)
            {
                [self setPipeline:@"vertex_main_basic" string:@"fragment_main_negative_lut"];
                float xpipi1 = [self.button_red doubleValue]/100.;
                float xpipi2 = [self.button_blue doubleValue]/100.;
                float xpipi3 = [self.button_green doubleValue]/100.;
                float xpipi[3] = {xpipi1, xpipi2, xpipi3};
                id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:xpipi length:sizeof(double[3]) options:MTLResourceStorageModeShared];
                [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            }
#pragma mark NEAREST INTERPOLATION
            else if(field_to_fill_type==19)
            {
                [self setPipeline:@"vertex_main_basic" string:@"fragment_main_nearest"];
                float xpipi1 = [self.nearest_value1 doubleValue]/100.;
                float xpipi2 = [self.nearest_value2 doubleValue]/100.;
                float xpipi3 = [self.nearest_value3 doubleValue]/100.;
                float xpipi[3] = {xpipi1, xpipi2, xpipi3};
                id<MTLBuffer> uniformsBuffer = [self.device newBufferWithBytes:xpipi length:sizeof(float[3]) options:MTLResourceStorageModeShared];
                [renderEncoder setFragmentBuffer:uniformsBuffer offset:0 atIndex:1];
            }

            if(is_image1)
                [renderEncoder setFragmentTexture:self.texture_out atIndex:0];
            else
                [renderEncoder setFragmentTexture:self.texture_out2 atIndex:0];
            
            [self setupRenderEncoder:renderEncoder];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
        }
    }
    auto end = std::chrono::steady_clock::now();
    NSString *nsString = [NSString stringWithUTF8String:("Time: " + std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count()) + "ms").c_str()];
    [self.time_value_field setStringValue:nsString];
}
-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

-(void)resetVertices {
    float vertices[] = {
            -1.0, -1.0, -1., -1.,
            1.0, -1.0, 1., -1.,
            -1.0, 1.0, -1., 1.,
            -1.0, 1.0, -1., 1.,
            1.0, 1.0, 1., 1.,
            1., -1., 1., -1.
        };
    
    numVertices = 6;
    self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
}

-(void)resizeMetalView
{
    if([self isImage1]){
        
        if(self.texture.width < self.texture.height)
            self.metalView.frame = CGRectMake(10, (580-self.texture.width*560./self.texture.height)/2, 560, self.texture.width*560./self.texture.height);
        else
            self.metalView.frame = CGRectMake(10, (580-self.texture.height*560./self.texture.width)/2, 560, self.texture.height*560./self.texture.width);
    }
        
    else
    {
        
        if(self.texture2.width < self.texture2.height)
            self.metalView2.frame = CGRectMake(930, (580-self.texture2.width*560./self.texture2.height)/2, 560, self.texture2.width*560./self.texture2.height);
        else
            self.metalView2.frame = CGRectMake(930, (580-self.texture2.height*560./self.texture2.width)/2, 560, self.texture2.height*560./self.texture2.width);
    }
}



-(void)interpolation_linear_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=21;
    [self draw_correctly];
}

- (void)interpolation_bicubic_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=20;
    [self draw_correctly];
}

- (void)interpolation_nearest_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=19;
    [self draw_correctly];
}

- (void)negative_lut_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=18;
    [self draw_correctly];
}

- (void)grayscale_gamma_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=17;
    [self draw_correctly];
}

- (void)effect_difference_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=16;
    [self draw_correctly];
}

- (void)edge_detection_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=15;
    [self draw_correctly];
}

- (void)mix_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=14;
    [self draw_correctly];
}

- (void)grayscale_negative_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=13;
    [self draw_correctly];
}

- (void)negative_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=12;
    [self draw_correctly];
}

- (void)lut_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=11;
    [self draw_correctly];
}

- (void)gamma_correction_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=10;
    [self draw_correctly];
}

- (void)blur_kawase_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=9;
    [self draw_correctly];
}

- (void)blur2_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=8;
    [self draw_correctly];
}

- (void)blur1_pushed {
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=7;
    [self draw_correctly];
}

- (void)grayscale_pushed{
    [self resetVertices];
    [self resizeMetalView];
    field_to_fill_type=6;
    [self draw_correctly];
}

- (void)chessboard_pushed {
    [self resetVertices];
    if([self isImage1] && self.texture_out!=nil)
        self.metalView.frame = CGRectMake(10, 10, 560, 560);
    else if([self isImage1] && self.texture_out2!=nil)
        self.metalView2.frame = CGRectMake(930, 10, 560, 560);
    field_to_fill_type = 4;
    [self draw_correctly];
}

- (void)functionSetter {
        if([self isEqToString:@"Grayscale"]) [self grayscale_pushed];
        if([self isEqToString:@"Blur 1"]) [self blur1_pushed];
        if([self isEqToString:@"Blur 2"]) [self blur2_pushed];
        if([self isEqToString:@"Blur Kawase"]) [self blur_kawase_pushed];
        if([self isEqToString:@"Negative"]) [self negative_pushed];
        if([self isEqToString:@"Grayscale + Negative"]) [self grayscale_negative_pushed];
        if([self isEqToString:@"Gamma correction"]) [self gamma_correction_pushed];
        if([self isEqToString:@"Grayscale + Gamma"]) [self grayscale_gamma_pushed];
        if([self isEqToString:@"Lut"]) [self lut_pushed];
        if([self isEqToString:@"Negative + Lut"]) [self negative_lut_pushed];
        if([self isEqToString:@"Mix: Chessboard + Image"]) [self mix_pushed];
        if([self isEqToString:@"Edge detection"]) [self edge_detection_pushed];
        if([self isEqToString:@"Interpolation - Bicubic"]) [self interpolation_bicubic_pushed];
        if([self isEqToString:@"Interpolation - Linear"]) [self interpolation_linear_pushed];
        if([self isEqToString:@"Interpolation - Nearest"]) [self interpolation_nearest_pushed];
        if([self isEqToString:@"Effect difference"]) if(self.texture2!=nil) [self effect_difference_pushed];
}

- (IBAction)invokeFunction:(id)sender {
    [self.time_value_field setHidden:NO];
    if([self isEqToString:@"One triangle render"]) [self one_triangle_pushed];
    else if([self isEqToString:@"Two triangle render"]) [self two_triangle_pushed];
    else if([self isEqToString:@"Multiple triangle render"]) [self multiple_triangle_pushed];
    else if([self isEqToString:@"Chessboard"]) [self chessboard_pushed];
    else
    {
        if([self isImage1]){
            if(self.texture!=nil) [self functionSetter];
        }
        else{
            if(self.texture2!=nil) [self functionSetter];
        }
    }
}


- (IBAction)insert_pushed:(id)sender {
    NSError *error = nil;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.allowedFileTypes = [NSImage imageTypes];
    panel.allowsMultipleSelection = NO;

    NSInteger result = [panel runModal];
    if (result == NSModalResponseOK) {
        NSURL *imageURL = panel.URLs.firstObject;
        _imageData = [NSData dataWithContentsOfURL:imageURL];
        MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
        if([self isImage1]){
            self.texture = [textureLoader newTextureWithData:_imageData options:@{ MTKTextureLoaderOptionSRGB : @NO } error:&error];
            self.texture_out = [textureLoader newTextureWithData:_imageData options:@{ MTKTextureLoaderOptionSRGB : @NO } error:&error];
            
            if(self.texture.width < self.texture.height)
                self.metalView.frame = CGRectMake(10, (580-self.texture.width*560./self.texture.height)/2, 560, self.texture.width*560./self.texture.height);
            else
                self.metalView.frame = CGRectMake(10, (580-self.texture.height*560./self.texture.width)/2, 560, self.texture.height*560./self.texture.width);
            
        }
            
        else
        {
            self.texture2 = [textureLoader newTextureWithData:_imageData options:@{ MTKTextureLoaderOptionSRGB : @NO } error:&error];
            self.texture_out2 = [textureLoader newTextureWithData:_imageData options:@{ MTKTextureLoaderOptionSRGB : @NO } error:&error];
            
            if(self.texture2.width < self.texture2.height)
                self.metalView2.frame = CGRectMake(930, (580-self.texture2.width*560./self.texture2.height)/2, 560, self.texture2.width*560./self.texture2.height);
            else
                self.metalView2.frame = CGRectMake(930, (580-self.texture2.height*560./self.texture2.width)/2, 560, self.texture2.height*560./self.texture2.width);
            
            
        }
            
        
        [self resetVertices];
    }
    
    field_to_fill_type = 5;
    [self draw_correctly];
}

- (IBAction)reset_pushed:(id)sender {
    [self resetVertices];
    [self.gamma_value setDoubleValue:50.];
    [self.gamma_grayscale_value setDoubleValue:50.];
    [self.edge_detection_value setDoubleValue:50.];
    [self.button_red setDoubleValue:100];
    [self.button_green setDoubleValue:100];
    [self.button_blue setDoubleValue:100];
    [self.text_chessboard_height setDoubleValue:10];
    [self.text_chessboard_width setDoubleValue:10.];
    field_to_fill_type = 5;
    
    if([self isImage1])
        self.texture_out = self.texture;
    else
        self.texture_out2 = self.texture2;
    [self draw_correctly];
}

- (void)multiple_triangle_pushed {
    
    Vertex vertexData[48];
    float temp = 2./8.;
    float start = -1.;
    for(int i=0; i<=7; i++)
    {
        vertexData[6*i] = {{start+i*temp, 0.5, 0.},{1.,0.,0.}};
        vertexData[6*i+1] = {{start+i*temp, -0.5, 0.},{0.,1.,0.}};
        vertexData[6*i+2] = {{start+i*temp+temp, -0.5, 0.},{0.,0.,1.}};
    }
    for(int i=0; i<=7; i++)
    {
        vertexData[6*i+3] = {{start+i*temp, 0.5, 0.},{0.,0.5,0.}};
        vertexData[6*i+4] = {{start+i*temp+temp, 0.5, 0.},{0.,0.7,0.}};
        vertexData[6*i+5] = {{start+i*temp+temp, -0.5, 0.},{1.,0.,1.}};
    }
    
    numVertices = 48;
    self.vertexBuffer = [self.device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
    field_to_fill_type = 3;
    
    if([self isImage1] && self.texture_out!=nil)
        self.metalView.frame = CGRectMake(10, 10, 560, 560);
    else if(![self isImage1] && self.texture_out2!=nil)
        self.metalView2.frame = CGRectMake(930, 10, 560, 560);
    
    [self draw_correctly];
}


- (void)two_triangle_pushed {
    Vertex vertexData[] =
    {
        {{-1., 1., 0.}, {1., 0., 0.}},
        {{0., 1., 0.}, {0., 1., 0.}},
        {{-1., -1., 0.}, {0., 0., 1.}},
        {{1., -1., 0.}, {1., 1., 0.}},
        {{0., -1., 0.}, {0., 1., 1.}},
        {{1., 1., 0.}, {1., 0., 1. }}
    };
    
    numVertices = 6;
    self.vertexBuffer = [self.device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
    field_to_fill_type = 2;
    
    if([self isImage1] && self.texture_out!=nil)
        self.metalView.frame = CGRectMake(10, 10, 560, 560);
    else if(![self isImage1] && self.texture_out2!=nil)
        self.metalView2.frame = CGRectMake(930, 10, 560, 560);
    
    [self draw_correctly];
}

- (void)one_triangle_pushed {
    
    Vertex vertexData[] =
    {
        {{-1., -1., 0.}, {1., 0., 0.}},
        {{0., 1., 0.}, {1., 0., 0.}},
        {{1., -1., 0.}, {1., 0., 0.}},
    };
    
    numVertices = 3;
    self.vertexBuffer = [self.device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
    field_to_fill_type = 1;
    
    if([self isImage1] && self.texture_out!=nil)
        self.metalView.frame = CGRectMake(10, 10, 560, 560);
    else if(![self isImage1] && self.texture_out2!=nil)
        self.metalView2.frame = CGRectMake(930, 10, 560, 560);

    [self draw_correctly];
}

@end

