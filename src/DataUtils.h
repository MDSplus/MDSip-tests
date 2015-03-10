#ifndef DATAUTILS_H
#define DATAUTILS_H


#include <cmath>
#include <limits>

#include <sys/time.h>
#include <utility>
#include <vector>
#include <algorithm>

#include "ClassUtils.h"
#include "Threads.h"

#include "StatisticsUtils.h"
#include "FileUtils.h"



////////////////////////////////////////////////////////////////////////////////
//  DataUtils  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < typename T >
inline bool are_same(T a, T b) {
    return std::fabs(a - b) < std::numeric_limits<T>::epsilon();
}



////////////////////////////////////////////////////////////////////////////////
//  Named  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Named
{
public:    
    Named(const char *name = "") :
        m_name(name)
    {}

    std::string & operator()() { return m_name; }

    const std::string & operator()() const { return m_name; }

    void SetName(std::string name) { m_name = name; }

    std::string GetName() const { return m_name; }

    template < class Archive >
    friend void serialize(Archive &ar, Named &n) {
        ar & n.m_name;
    }

private:
    std::string m_name;
};




////////////////////////////////////////////////////////////////////////////////
//  Timer  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Timer
{
public:
    void Start() { gettimeofday(&m_start, NULL); }

    double StopWatch() {
        gettimeofday(&m_end, NULL);
        double timeSec = m_end.tv_sec - m_start.tv_sec +
                (m_end.tv_usec - m_start.tv_usec)*1E-6;
        return timeSec;
    }

private:
    struct timeval m_start, m_end;
};





//////////////////////////////////////////////////////////////////////////////////
////  Point2D  ///////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


//template <typename _Scalar>
//struct Point2D {

//    Point2D() {
//        m_data[0] = 0;
//        m_data[1] = 0;
//    }

//    Point2D(_Scalar x, _Scalar y) {
//        m_data[0] = x;
//        m_data[1] = y;
//    }

//    typedef CommaInitializer< Point2D<_Scalar> , _Scalar >  CommaInit;

//    inline CommaInit operator <<(_Scalar scalar) {
//        return CommaInit(this, scalar);
//    }

//    _Scalar & operator() (const unsigned int i) { return m_data[i]; }
//    const _Scalar & operator() (const unsigned int i) const { return m_data[i]; }

//    template < typename _Other >
//    operator Point2D<_Other> () {
//        return Point2D<_Other> (static_cast<_Other>(m_data[0]), static_cast<_Other>(m_data[1]) );
//    }

//    friend std::ostream &
//    operator << (std::ostream &o, const Point2D<_Scalar> &pt) {
//        return o << pt(0) << "," << pt(1);
//    }

//private:
//    friend class CommaInitializer< Point2D<_Scalar> , _Scalar >;
//    void resize(int i) {}

//    _Scalar m_data[2];
//};


////////////////////////////////////////////////////////////////////////////////
//  Tuple  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



template < typename _Scalar, unsigned int _Dim >
class Tuple
{
    typedef Tuple<_Scalar,_Dim> ThisClass;

public:

    typedef _Scalar ScalarType;

    Tuple() {
        //        std::fill( m_data, m_data + sizeof(m_data), 0 );
        for(unsigned int i = 0; i<_Dim; ++i)
            m_data[i] = 0;
    }

    Tuple(_Scalar x, _Scalar y = 0, _Scalar z = 0) {
        _Scalar *args[3] = {&x,&y,&z};
        for(unsigned int i = 0; i<_Dim; ++i)
            m_data[i] = *args[i];
    }

    typedef CommaInitializer< ThisClass , _Scalar >  CommaInit;

    inline CommaInit operator << (_Scalar scalar) {
        return CommaInit(this, scalar);
    }

    _Scalar & operator() (const size_t i) { assert(i<_Dim); return m_data[i]; }
    const _Scalar & operator() (const size_t i) const { assert(i<_Dim); return m_data[i]; }

    template < typename _Other >
    Tuple<_Other,_Dim> cast() {
        Tuple<_Other,_Dim> cast_out;
        for(unsigned int i = 0; i<_Dim; ++i)
            cast_out.m_data[i] = static_cast<_Other>(this->m_data[i]);
        return cast_out;
    }

    template < typename _Other >
    inline operator Tuple<_Other,_Dim> () {
        return this->cast<_Other>();
    }

    inline friend bool operator < (const ThisClass &t1, const ThisClass &t2) {
        return t1(0) < t2(0);
    }

    inline friend bool operator == (const ThisClass &t1, const ThisClass &t2) {
        bool out = 1;
        for(unsigned int i = 0; i<_Dim; ++i) {
            out &= t1.m_data[i] == t2.m_data[i];
        }
        return out;
    }

    friend std::ostream &
    operator << (std::ostream &o, const ThisClass &pt) {
        for(unsigned int i=0; i<_Dim-1; ++i) o << pt(i) << ",";
        return o << pt(_Dim-1);
    }

    friend std::istream &
    operator >> (std::istream &is, ThisClass &v) {
        char sep; // any separator //
        for(unsigned int i=0; i<_Dim-1; ++i) is >> v(i) >> sep;
        is >> v(_Dim-1);
        return is;
    }

private:
    friend class CommaInitializer< Tuple<_Scalar,_Dim> , _Scalar >;
    template <typename _Other, unsigned int _OtherDim> friend class Tuple;

    void resize(int i) {}

    _Scalar m_data[_Dim];
};


typedef Tuple<float,2> Vector2f;
typedef Tuple<float,3> Vector3f;
typedef Tuple<float,4> Vector4f;

typedef Tuple<double,2> Vector2d;
typedef Tuple<double,3> Vector3d;
typedef Tuple<double,4> Vector4d;

typedef Tuple<int,2> Vector2i;
typedef Tuple<int,3> Vector3i;
typedef Tuple<int,4> Vector4i;

typedef Vector3d Point2D;










////////////////////////////////////////////////////////////////////////////////
//  Curve2D  ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class Curve2D : /*Lockable,*/ public Named
{
public:
    typedef Vector3d Point;   // (X, Y, RMS ERROR) //

public:    

    struct Axis {
        Axis() : ticks(1)
        {
            limits[0] = 0;
            limits[1] = 0;
        }

        std::string name;
        double limits[2];
        double ticks;
    };

    Curve2D() {}

    Curve2D(const char *name) :
        Named(name)
    {}

    size_t Size() const { return m_data.size(); }

    template < typename _T >
    void AddPoint( const Tuple<_T,3> &pt ) {
//        MDS_LOCK_SCOPE(*this);
        m_data.push_back ( (Point)pt );
    }

    friend std::ostream &
    operator << (std::ostream &o, const Curve2D &curve) {
        o<< "Curve: " << curve.GetName() << "\n";
        for(size_t i=0; i<curve.m_data.size(); ++i) {
            const Point &pt = curve.m_data[i];
            o << pt(0) << "," << pt(1) << "\n";
        }
        return o;
    }

    void Update() {        
        //        for(size_t i = 0; i < m_data.size(); ++i) {
        //            XAxis().limits[0] = std::min( min, m_data.at(i)(0) );
        //            XAxis().limits[1] = std::max( max, m_data.at(i)(0) );
        //            YAxis().limits[0] = std::min( min, m_data.at(i)(1) );
        //            YAxis().limits[1] = std::max( max, m_data.at(i)(1) );
        //        }
        std::sort(m_data.begin(),m_data.end());
    }

    inline Axis & GetAxis(unsigned int i) { return m_axis[i]; }
    inline const Axis & GetAxis(unsigned int i) const { return m_axis[i]; }
    inline Axis & XAxis() { return GetAxis(0); }
    inline const Axis & XAxis() const { return GetAxis(0); }
    inline Axis & YAxis() { return GetAxis(1); }
    inline const Axis & YAxis() const { return GetAxis(1); }

    std::vector<Point> &Points() { return m_data; }
    const std::vector<Point> &Points() const { return m_data; }

    Point & operator[](size_t id) { return m_data[id]; }
    const Point & operator[](size_t id) const { return m_data[id]; }



private:
    std::vector<Point> m_data;
    Axis m_axis[2];
};




////////////////////////////////////////////////////////////////////////////////
//  Accumulator  ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

template < typename T >
class Accumulator : public Named
{
public:
    Accumulator() : Named() {}

    Accumulator(const Accumulator &other) :
        Named(other),
        m_min(other.m_min), m_max(other.m_max), m_sum(other.m_sum),
        m_stat(other.m_stat)
    {}

    Accumulator(const char *name) :
        Named(name),
        m_min(0),
        m_max(0),
        m_sum(0)
    {}


    void Push(const T data) {
        m_min = std::min(m_min,data);
        m_max = std::max(m_max,data);
        m_sum += data;
        m_stat << data;
    }

    inline void operator << (const T data) { Push(data); }

    void Clear() {
        m_min = m_max = m_sum = 0;
        m_stat.clear();
    }

    T Max() const { return m_max; }
    T Min() const { return m_min; }
    T Sum() const { return m_sum; }

    size_t Size() const { return m_stat.size(); }
    double Mean() const { return m_stat.mean(); }
    double Variance() const { return m_stat.variance(); }
    double Rms() const { return m_stat.rms(); }

    void operator += (const Accumulator &other) {
        m_min = std::min(m_min, other.m_min);
        m_max = std::max(m_max, other.m_max);
        m_sum += other.m_sum;
        m_stat += other.m_stat; // see stat operator //
    }

    void PrintSelfInline(std::ostream &o) const {
        o << "Accumulator(\"" << this->GetName() << "\") [" << m_min << "," << m_max << "]"
          << " tot:" << m_sum << " mean:" << Mean() << " rms:" << Rms();
    }    

    /// Print to ostreem
    friend std::ostream &
    operator << (std::ostream &o, const Accumulator<T> &_this) {
        _this.PrintSelfInline(o);
        return o;
    }

    template < class Archive >
    friend void serialize(Archive &ar, Accumulator &h) {
        ar & h.m_min & h.m_max & h.m_sum & h.m_stat;
        ar & (Named &)h;
    }

protected:
    T m_min,m_max,m_sum;
    StatUtils::IncrementalOrder2 m_stat;
};




////////////////////////////////////////////////////////////////////////////////
//  Histogram  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < typename T >
class Histogram : public Accumulator<T>
{

    typedef Accumulator<T> BaseClass;

public:

    Histogram() {} // required by map container //

    Histogram(const char *name, size_t nbin, const T min, const T max) :
        BaseClass(name),
        m_value_name(name),
        m_bins(nbin),
        m_underf(0), m_overf(0)
    { m_limits[0] = min, m_limits[1] = max; }

    void Push(const T data) {        
        int bin = this->get_bin(data);
        if(bin < 0)
            ++m_underf;
        else if (bin >= (int)BinSize())
            ++m_overf;
        else {
            ++m_bins.at( bin );
            m_stat << data;
        }
        BaseClass::Push(data);
    }

    void Clear() {
        std::fill(m_bins.begin(), m_bins.end(), 0);
        m_overf = m_underf = 0;
        m_stat = StatUtils::IncrementalOrder2();
        BaseClass::Clear();
    }

    inline size_t CollectedSize() const { return m_stat.size(); }

    inline size_t BinSize() const { return m_bins.size(); }

    inline void operator<<(const T data) { Push(data); }

    inline std::pair<T,size_t> operator[](unsigned int bin) const { return std::make_pair(get_pos(bin),m_bins.at(bin)); }

    inline size_t operator()(const T pos) const { return m_bins.at(get_bin(pos)); }


    double Mean() const { return m_stat.mean(); }

    double MeanAll() const { return BaseClass::Mean(); }

    double Variance() const { return m_stat.variance(); }

    double VarianceAll() const { return BaseClass::Variance(); }

    double Rms() const { return m_stat.rms(); }

    double RmsAll() const { return BaseClass::Rms(); }    

    void PrintSelf(std::ostream &o, const char _c = ';') const {
        o << "Histogram" << _c << this->m_value_name << "\n";
        for(size_t i=0; i< this->BinSize(); ++i)
            o << this->get_pos(i) << _c << this->m_bins[i] << "\n";
    }

    void PrintSelfInline(std::ostream &o) const {
        static const char *lut = "_,.-''"; // 5 levels histogram //
        double max = *std::max_element(m_bins.begin(), m_bins.end());        
        o << "Histogram(\"" << this->GetName() << "\"," << this->BinSize() << "," << m_limits[0] << "," << m_limits[1] << ")";
        o << "  " << m_underf << " [";
        for(size_t i=0; i<this->BinSize(); ++i) {
            double val = (double)m_bins[i];
            unsigned int lid = max > 0 ? (int)floor(val/max * 5) : 0;
            o << lut[lid];
        }
        o << "] " << m_overf << " ";
        o << " visible -> mean:" << this->Mean() << " rms:" << this->Rms();
    }

    /// Convert to a Curve object
    operator Curve2D () const {
        Curve2D curve(this->GetName().c_str());
        curve.XAxis().name = "Histogram";
        curve.YAxis().name = this->m_value_name;
        for(size_t i=0; i<this->BinSize(); ++i)
            curve.AddPoint( Vector3d(get_pos(i) + get_spacing()/2, m_bins[i]) );
        curve.Update();
        return curve;
    }

    /// external inserter
    template < typename _OtherScalar >
    friend Histogram & operator << (Histogram &h, const _OtherScalar data) {
        h.Push(data);
        return h;
    }


    /// Print to ostreem
    friend std::ostream &
    operator << (std::ostream &o, const Histogram<T> &_this) {
        //        _this.PrintSelf(o);
        _this.PrintSelfInline(o);
        return o;
    }

    /// Print to CSV file
    friend CsvDataFile &
    operator << (CsvDataFile &o, const Histogram &plot) {
        const char _c = o.Separator();
        plot.PrintSelf(o,_c);
        return o;
    }


    static Histogram merge(const Histogram &h1, const Histogram &h2) {
        // TODO: very bad ... works only if h have the same bins //
        assert(h1.BinSize() == h2.BinSize());
        assert(h1.m_limits[0] == h2.m_limits[0]);
        assert(h1.m_limits[1] == h2.m_limits[1]);

        Histogram out = h1;
        for(unsigned int i=0; i<h1.BinSize(); ++i) {
            out.m_bins[i] += h2.m_bins[i];
        }        
        out.Accumulator<T>::operator +=((Accumulator<T>)h2);
        out.m_stat += h2.m_stat;
        out.m_underf += h2.m_underf;
        out.m_overf += h2.m_overf;

        return out;
    }

    template < class Archive >
    friend void serialize(Archive &ar, Histogram &h) {
        ar
                & (Accumulator<T> &)h
                & h.m_value_name
                & h.m_bins
                & h.m_limits
                & h.m_underf & h.m_overf
                & h.m_stat;
    }

private:

    T get_spacing() const {
        return (m_limits[1] - m_limits[0]) / this->BinSize();
    }

    int get_bin(const T data) const {
        T bin_size = get_spacing();
        return (int)floor( (data-m_limits[0]) /bin_size);
    }

    T get_pos(const int bin) const {
        T bin_size = get_spacing();
        return m_limits[0] + (bin_size) * bin;
    }

    std::string m_value_name;
    std::vector<size_t> m_bins;
    T m_limits[2];
    size_t m_underf, m_overf;
    StatUtils::IncrementalOrder2 m_stat;
};









////////////////////////////////////////////////////////////////////////////////
//  ColorRGB  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ColorRGB : public Tuple<unsigned char,3>
{
    typedef Tuple<unsigned char,3> BaseClass;
    typedef BaseClass::ScalarType ScalarType;

public:
    ColorRGB() {}

    ColorRGB(const ScalarType R,const ScalarType G,const ScalarType B) : BaseClass(R,G,B) {}
    ColorRGB(const char *SharpRGB);

    ScalarType & R() { return this->operator ()(0); }
    const ScalarType & R() const { return this->operator ()(0); }
    ScalarType & G() { return this->operator ()(1); }
    const ScalarType & G() const { return this->operator ()(1); }
    ScalarType & B() { return this->operator ()(2); }
    const ScalarType & B() const { return this->operator ()(2); }

    std::string ToString() const;


private:

};



////////////////////////////////////////////////////////////////////////////////
//  ColorRGBList  //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ColorRGBList
{
public:
    ColorRGBList() {}

    struct Entry {
        std::string name;
        ColorRGB    color;
        Entry(const std::string n, const ColorRGB c) : name(n), color(c) {}
    };

    const std::vector<Entry> & ColorList() const { return m_color_list; }
    std::vector<Entry> & ColorList() { return m_color_list; }

    std::vector<Entry> & operator ()() {
        return ColorList();
    }

private:

    std::vector<Entry> m_color_list;

};



////////////////////////////////////////////////////////////////////////////////
//  Plot  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Plot2D : public Named
{
public:

    typedef Curve2D        CurveType;
    typedef Curve2D::Axis  AxisType;
    typedef Curve2D::Point PointType;

    Plot2D(const char *name) : Named(name) {}

    size_t GetNumberOfPlots() const { return m_curves.size(); }

    void AddCurve(const Curve2D &curve) {
         m_curves.push_back(curve);
         m_curves_flags.push_back( OptionFlags(ShowLines | ShowPoints | Smoothed) );
         if(m_Xaxis.empty()) m_Xaxis.push_back(curve.XAxis());
         if(m_Yaxis.empty()) m_Yaxis.push_back(curve.YAxis());
    }

    inline AxisType & XAxis(unsigned int i = 0) { return m_Xaxis.at(i); }
    inline const AxisType & XAxis(unsigned int i = 0) const { return m_Xaxis.at(i); }
    inline AxisType & YAxis(unsigned int i = 0) { return m_Yaxis.at(i); }
    inline const AxisType & YAxis(unsigned int i = 0) const { return m_Yaxis.at(i); }

    std::string GetSubtitle() const { return m_subtitle; }
    void SetSubtitle(const std::string &subtitle) { m_subtitle = subtitle; }

    Curve2D & Curve(int i) { return m_curves[i]; }

    void PrintToCsv( std::ostream &o, const char sep = ';' );

    void PrintToCsv( std::string file_name, const char sep = ';' );

    void PrintToGnuplotFile(std::string file_name = "") const;

    friend CsvDataFile &
    operator << (CsvDataFile &csv, Plot2D &plot) {
        plot.PrintToCsv(csv, csv.Separator());
        return csv;
    }

    enum OptionEnum {
        Smoothed    = 1 << 0,
        ShowLines   = 1 << 1,
        ShowPoints  = 1 << 2,
        ShowBars    = 1 << 3
    };
    typedef Flags<enum OptionEnum> OptionFlags;

    OptionFlags & CurveFlags(unsigned int i) { return m_curves_flags[i]; }
    const OptionFlags & CurveFlags(unsigned int i) const { return m_curves_flags[i]; }

private:
    std::vector<AxisType> m_Xaxis;
    std::vector<AxisType> m_Yaxis;
    std::vector<Curve2D>     m_curves;
    std::vector<OptionFlags> m_curves_flags;

    std::string m_subtitle;

    static Singleton<ColorRGBList> s_chart_colors;

};


DEFINE_OPERATORS_FOR_FLAGS(Plot2D::OptionFlags)











#endif // DATAUTILS_H

