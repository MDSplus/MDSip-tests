#ifndef DATAUTILS_H
#define DATAUTILS_H


#include <sys/time.h>
#include <utility>
#include <vector>
#include <algorithm>

#include "ClassUtils.h"
#include "Threads.h"

#include "StatisticsUtils.h"
#include "FileUtils.h"

////////////////////////////////////////////////////////////////////////////////
//  Named  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Named
{
public:
    Named() : m_name("") {}

    Named(const std::string name) :
        m_name(name)
    {}

    std::string & operator()() { return m_name; }

    const std::string & operator()() const { return m_name; }

    void SetName(std::string name) { m_name = name; }

    std::string GetName() const { return m_name; }

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





////////////////////////////////////////////////////////////////////////////////
//  Point2D  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template <typename _Scalar>
struct Point2D {

    Point2D() {
        m_data[0] = 0;
        m_data[1] = 0;
    }

    Point2D(_Scalar x, _Scalar y) {
        m_data[0] = x;
        m_data[1] = y;
    }

    typedef CommaInitializer< Point2D<_Scalar> , _Scalar >  CommaInit;

    inline CommaInit operator <<(_Scalar scalar) {
        return CommaInit(this, scalar);
    }

    _Scalar & operator() (const unsigned int i) { return m_data[i]; }
    const _Scalar & operator() (const unsigned int i) const { return m_data[i]; }

    template < typename _Other >
    operator Point2D<_Other> () {
        return Point2D<_Other> (static_cast<_Other>(m_data[0]), static_cast<_Other>(m_data[1]) );
    }

    friend std::ostream &
    operator << (std::ostream &o, const Point2D<_Scalar> &pt) {
        return o << pt(0) << "," << pt(1);
    }

private:
    friend class CommaInitializer< Point2D<_Scalar> , _Scalar >;
    void resize(int i) {}

    _Scalar m_data[2];
};






////////////////////////////////////////////////////////////////////////////////
//  Curve2D  ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// FINIRE //

class Curve2D : /*Lockable,*/ public Named
{
    typedef Point2D<double> Point;

    static bool point_cmp (const Point &p1, const Point &p2) {
        return p1(0) < p2(0);
    }

public:

    struct Axis {
        Axis() :
            ticks(1)
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

    template < typename _T >
    void AddPoint( const Point2D<_T> &pt ) {
        //MDS_LOCK_SCOPE(*this);
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
        for(size_t i = 0; i < m_data.size(); ++i) {
            double &min = XAxis().limits[0];
            double &max = XAxis().limits[1];
            min = std::min( min, m_data.at(i)(0) );
            max = std::max( max, m_data.at(i)(1) );
        }
        std::sort(m_data.begin(),m_data.end(),point_cmp);
    }

    inline Axis & GetAxis(unsigned int i) { return m_axis[i]; }
    inline Axis & XAxis() { return GetAxis(0); }
    inline Axis & YAxis() { return GetAxis(1); }

    std::vector<Point> &Points() { return m_data; }
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
    Accumulator() {}

    Accumulator(const Accumulator &other) : Named(other) {}

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

    void Clear() {
        m_min = m_max = m_sum = 0;
        m_stat = StatUtils::IncrementalOrder2();
    }

    T Max() const { return m_max; }
    T Min() const { return m_min; }
    T Sum() const { return m_sum; }

    size_t Size() const { return m_stat.size(); }
    double Mean() const { return m_stat.mean(); }
    double Variance() const { return m_stat.variance(); }
    double Rms() const { return m_stat.rms(); }

private:
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
//        m_limits(min,max),
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
        o << "histogram: [" << this->BinSize() << "," << m_limits[0] << "," << m_limits[1] << "]";
        o << "  " << m_underf << " [";
        for(size_t i=0; i<this->BinSize(); ++i) {
            double val = (double)m_bins[i];
            unsigned int lid = max > 0 ? (int)floor(val/max * 5) : 0;
            o << lut[lid];
        }
        o << "] " << m_overf << " ";
    }

    /// Convert to a Curve object
    operator Curve2D () {
        Curve2D curve(this->GetName().c_str());
        curve.XAxis().name = "Histogram";
        curve.YAxis().name = this->m_value_name;
        for(size_t i=0; i<this->BinSize(); ++i)
            curve.AddPoint( Point2D<double>(get_pos(i) + get_spacing()/2, m_bins[i]) );
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
//  Plot  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Plot2D : public Named
{
public:

    typedef Curve2D::Axis Axis;

    Plot2D(const char *name) :
        Named(name),
        m_axis(2)
    {}

    size_t GetNumberOfPlots() const { return m_curves.size(); }

    void AddCurve(const Curve2D &curve) {
         m_curves.push_back(curve);
    }

    inline Axis & GetAxis(unsigned int i) { return m_axis[i]; }
    inline Axis & XAxis() { return GetAxis(0); }
    inline Axis & YAxis() { return GetAxis(1); }

    Curve2D &Curve(int i) { return m_curves[i]; }


    void PrintCsvEasy( CsvDataFile &file ) {
        (void) file;
        // FARE: //
    }

    friend CsvDataFile &
    operator << (CsvDataFile &csv, const Plot2D &plot) {
        //        const char c = csv.Separator(); (void)c;
        //        double pos = 0;


        // FARE: //
        return csv;
    }

private:
    std::vector<Axis> m_axis;
    std::vector<Curve2D> m_curves;
};













#endif // DATAUTILS_H

