
#include <mdsobjects.h>
#include <cstdlib>
#include <ctime>

#include "TreeUtils.h"
#include "TestContent.h"

#include <math.h>

using namespace MDSplus;


static double box_muller(double x)
{
    (void)x;
    static const double mean = 0;
    static const double sigma = 1;

    float x1, x2, w, y1;
    static double y2;
    static int use_last = 0;

    if (use_last)
    {
        y1 = y2;
        use_last = 0;
    }
    else
    {
        do {
            x1 = 2.0 * (double)rand() / RAND_MAX - 1.0;
            x2 = 2.0 * (double)rand() / RAND_MAX - 1.0;
            w = x1 * x1 + x2 * x2;
        } while ( w >= 1.0 );

        w = sqrt( (-2.0 * log( w ) ) / w );
        y1 = x1 * w;
        y2 = x2 * w;
        use_last = 1;
    }
    return( mean + y1 * sigma );
}

static double noise_white(double x) {
    (void)x;
    return (double)rand() / RAND_MAX;
}



////////////////////////////////////////////////////////////////////////////////
//  ContentSine  ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


ContentFunction::ContentFunction(const char *name) :
    Content(name),
    m_subtree(NULL),
    m_sample_time(1E-3),
    m_current_time(0),
    m_func(NULL)
{
    this->SetGenFunction(Sine);
}

ContentFunction::~ContentFunction()
{    
    m_mutex.lock(); // BUG? mutex must be locked prior to be destroyed.
    if(m_subtree) delete m_subtree;
}

void ContentFunction::SetGenFunction(const ContentFunction::FunctionEnum funt)
{
    switch (funt) {
    case ContentFunction::Sine:
        m_func = &sin;
        break;
    case ContentFunction::NoiseG:
        m_func = &box_muller;
        break;
    case ContentFunction::NoiseW:
        m_func = &noise_white;
        break;

    }
}



Content::Element ContentFunction::GetNextElement(size_t size_KB)
{    
    float current_time;
    float end_time;
    Element el;
    size_t size = GetKByteSizeIn<float>(size_KB); // number of samples //

    {
        AutoLock al(m_mutex); (void)al;
        current_time = m_current_time;
        end_time = current_time + m_sample_time * (size-1);
        m_current_time = end_time + m_sample_time;
    } // atomic

    std::vector<float> data(size);

    for(unsigned int i=0; i<size; ++i) {
        data[i] = m_func(current_time + m_sample_time * i);
    }

    // fill element //
    el.path = m_name;
    el.data = new Float32Array(&data.front(),size);
    el.dim  = new Range(new Float32(current_time), new Float32(end_time), new Float32(m_sample_time));

    return el;
}





////////////////////////////////////////////////////////////////////////////////
//  IMAGE   ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



// IMAGE //

//#include <math.h>
//#include <mdsobjects.h>
//#define WIDTH 640
//#define HEIGHT 480
//#define NUM_FRAMES 100
//#define PI 3.14159
//using namespace MDSplus;

//int main(int argc, char *argv)
//{
//    try {
//        Tree *t = new Tree("test", 1);
//        TreeNode *node = t->getNode("\\segmented");
//        node->deleteData();
//        short *currFrame = new short[WIDTH*HEIGHT];

//        for(int frameIdx = 0; frameIdx < NUM_FRAMES; frameIdx++)
//        {
//            /* get the angular coefficient of the current line */
//            double m = tan((2*PI*frameIdx)/NUM_FRAMES);

//            /* Prepare the current frame (black with a white line)  */
//            memset(currFrame, 0, WIDTH * HEIGHT * sizeof(short));
//            for(int i = 0; i < WIDTH; i++)
//            {
//                int j = (int)round((i-WIDTH/2)*m);
//                if(j >= -HEIGHT/2 && j < HEIGHT/2)
//                    currFrame[(j+HEIGHT/2)*WIDTH +i] = 255;
//            }

//            /* Time is the frame index */
//            /* Start time and end time for the current segment are the same (1 frame is contained) */
//            float currTime = frameIdx;
//            Data *startTime = new Float32(currTime);
//            Data *endTime   = new Float32(currTime);

//            /* Segment dimension is a 1D array with one element (the segment has one row) */
//            int oneDim = 1;
//            /* Data dimension is a 3D array where the last dimension is 1 */
//            Data *dim = new Float32Array(&currTime, 1, &oneDim);
//            int segmentDims[3];
//            /* unlike MDSplus C uses row-first ordering, so the last MDSplus dimension becomes the first one in C */
//            segmentDims[0] = 1;
//            segmentDims[1] = HEIGHT;
//            segmentDims[2] = WIDTH;

//            // data, ndims, dims //
//            Data *segment = new Int16Array(currFrame, 3, segmentDims);

//            /* Write the entire segment */
//            node->makeSegment(startTime, endTime, dim, (Array *)segment);

//            /* Free stuff */
//            deleteData(segment);
//            deleteData(startTime);
//            deleteData(endTime);
//            deleteData(dim);
//        }
//    }catch(MdsException *exc)
//    {
//        cout << "Error appending segments: " << exc->what();
//    }
//}
