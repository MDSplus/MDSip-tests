
#include <mdsobjects.h>
#include <cstdlib>
#include <ctime>

#include "TreeUtils.h"
#include "TestContent.h"
#include "StatisticsUtils.h"

#include <math.h>

using namespace MDSplus;



////////////////////////////////////////////////////////////////////////////////
//  Time Function Generated Content  ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


ContentFunction::ContentFunction(const char *name, size_t size_MB) :
    Content(name),
    m_size(1024*size_MB),
    m_sample_time(1E-3),
    m_current_sample(0),
    m_func(NULL),
    m_subtree(NULL)
{
    this->SetGenFunction(Sine);
}

ContentFunction::~ContentFunction()
{
    if(m_subtree) delete m_subtree;
}

size_t ContentFunction::GetSize() const
{
    MDS_LOCK_SCOPE(*this);
    return m_size;
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


void ContentFunction::SetGenFunction(ContentFunction::GenFunction func)
{
    m_func = func;
}



bool ContentFunction::GetNextElement(size_t size_KB, Content::Element &el)
{    
    size_t current_sample;
    size_t size; // number of samples //
    float start_time;
    float end_time;    

    {
        MDS_LOCK_SCOPE(*this);
        if(m_size > 0) {
            size_KB = std::min(m_size, size_KB);
            m_size -= size_KB;
            size = GetKByteSizeIn<float>(size_KB);
        }
        else
            return false;
        current_sample = m_current_sample;
        m_current_sample += size;
    }

    start_time = current_sample * m_sample_time;
    end_time = (current_sample + size - 1) * m_sample_time;

    std::vector<float> data(size);
    for(unsigned int i=0; i<size; ++i) {        
        data[i] = m_func(m_sample_time * current_sample++);
    }

    // fill element //
    el.path = m_name;
    el.data = new Float32Array(&data.front(),size);
    el.dim  = new Range(new Float32(start_time), new Float32(end_time), new Float32(m_sample_time));
    return true;
}

void ContentFunction::ResetSize(size_t size_MB)
{
    MDS_LOCK_SCOPE(*this);
    this->m_size = 1024*size_MB;
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
