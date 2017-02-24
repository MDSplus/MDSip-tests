#include "DataUtils.h"

#include "stdio.h"
#include "math.h"

namespace mdsip_test {
  

////////////////////////////////////////////////////////////////////////////////
//  CURVE 2D  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void Curve2D::PrintSelf_abs(std::ostream &o, int nbins) const
{
    Histogram<double> to_hist;
    const std::string name = this->GetName();
    if (XAxis().limits[0] == XAxis().limits[1]) {
        double min=0,max=0;
        foreach(const Point &pt, m_data) {
            if(pt(0)<min) min=pt(0);
            if(pt(0)>max) max=pt(0);
        }
        to_hist = Histogram<double> (name.c_str(),nbins,min,max);
    }
    else
        to_hist = Histogram<double>(name.c_str(),nbins,XAxis().limits[0], XAxis().limits[1]);
    foreach(const Point &pt, m_data) {
        to_hist.Push(pt(0),pt(1));
    }
    o << to_hist;
}


////////////////////////////////////////////////////////////////////////////////
//  ColorRGB  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



ColorRGB::ColorRGB(const char *SharpRGB)
{
    std::stringstream ss(SharpRGB);
    char c;
    unsigned int num;
    ss >> c >> std::hex >> num;

    R() = (num / 0x10000) % 0x10000;
    G() = (num / 0x100) % 0x100;
    B() = num % 0x100;
}

std::string ColorRGB::ToString() const
{
    char str[8];
    sprintf(str,"#%02x%02x%02x", R(),G(),B());
    return std::string(str);
}



////////////////////////////////////////////////////////////////////////////////
//  PLOT 2D  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



static ColorRGBList init_color_list() {
    ColorRGBList colors;
    colors().push_back(ColorRGBList::Entry("dodgerblue4","#104E8B"));
    colors().push_back(ColorRGBList::Entry("indianred","#CD5C5C"));
    colors().push_back(ColorRGBList::Entry("sgi teal","#388E8E"));
    colors().push_back(ColorRGBList::Entry("orchid","#DA70D6"));
    colors().push_back(ColorRGBList::Entry("tomato","#FF6347"));
    colors().push_back(ColorRGBList::Entry("maroon","#800000"));
    colors().push_back(ColorRGBList::Entry("firebrick","#B22222"));
    colors().push_back(ColorRGBList::Entry("salmon","#FA8072"));
    return colors;
}


Singleton<ColorRGBList> Plot2D::s_chart_colors = init_color_list();

template < typename T >
static std::vector<T> vector_cat(const std::vector<T> &v1, const std::vector<T> &v2) {
    std::vector<T> out;
    out.insert(out.end(), v1.begin(), v1.end());
    out.insert(out.end(), v2.begin(), v2.end());
    return out;
}


void Plot2D::PrintToCsv(std::string file_name, const char sep)
{
    typedef std::vector<PointType>::iterator ItrType;
    std::vector<ItrType> itr,itr_end;
    std::ofstream o;

    std::vector<CurveType> m_curves = vector_cat(d[0].m_curves, d[1].m_curves);
    if(m_curves.empty()) throw std::logic_error("No curves to plot");

    bool split_files = false;
    foreach (Curve2D &curve, m_curves) {
        const int &n_points = m_curves.front().Size();
        if(n_points != curve.Size()) split_files = true;
        else for(int i=0; i<n_points; ++i)
            if(curve[i](0) != m_curves.front()[i](0))
                split_files = true;
    }
    
    if(split_files) {
        int curve_index = 0;
        foreach (Curve2D curve, m_curves) {            
            ++curve_index;
            if(curve.GetName().empty())
                curve.SetName(std::string("curve_"+curve_index));
            o.open(std::string(file_name+"_"+curve.GetName()+".csv").c_str());
            assert(o.is_open());
            o << this->XAxis().name << sep << curve.GetName() << sep << curve.GetName()+" err" << std::endl;
            foreach (Point2D &pt, curve.Points())
                o << pt(0) << sep << pt(1) << sep << pt(2) << std::endl;
            o.close();
        }
    }
    else {        
        o.open(std::string(file_name+".csv").c_str());
        assert(o.is_open());        
        o << this->XAxis().name;
        foreach (Curve2D &curve, m_curves) {
            curve.Update();
            if(curve.Size()) {
                o << sep << curve.GetName() << sep << curve.GetName()+" err";
                itr.push_back( curve.Points().begin() );
                itr_end.push_back( curve.Points().end() );            
            }
        }
        o << std::endl;        
        // TODO: find a better implementation //
        for(itr.front(); itr.front() != itr_end.front();) {
            ItrType min_pt;
            for(unsigned int i=0; i<itr.size(); ++i) {
                if(itr[i] != itr_end[i]) { min_pt = itr[i]; break; }
            }
            for(unsigned int i=0; i<itr.size(); ++i) {
                if (itr[i] != itr_end[i] && *itr[i] < *min_pt ) min_pt = itr[i];
            }
            o << (*min_pt)(0);
            for(unsigned int i=0; i<itr.size(); ++i) {
                ItrType &pt = itr[i];
                if( itr[i] != itr_end[i] && are_same((*pt)(0),(*min_pt)(0)))
                { o << sep << (*pt)(1) << sep << (*pt)(2); pt++; }
                else { o << sep << sep; }
            }
            o << std::endl;
        }
        o.close();
    }
}

template < typename T >
static std::string to_string(const T& val) {
    return static_cast<std::ostringstream*>( &(std::ostringstream() << val) )->str();
}


void Plot2D::print_plot_range(std::ofstream &o) const {
    // RANGES //
    for (int set = 0; set<SET_SIZE; ++set) {
        if(d[set].m_curves.empty()) continue;
        std::string setstr = (set) ? to_string(set+1) : "";
        o << "set y" << setstr << "tics nomirror \n";
        if(!are_same(XAxis(set).limits[0],XAxis(set).limits[1]) ) {
            o << "set x" << setstr << "range [";
            if(isnan(XAxis(set).limits[0])) o << "*";
            else o << XAxis(set).limits[0];
            o << ":";
            if(isnan(XAxis(set).limits[1])) o << "*";
            else o << XAxis(set).limits[1];
            o << "]\n";
        }
        if(!are_same(YAxis(set).limits[0],YAxis(set).limits[1]) ) {
            o << "set y" << setstr << "range [";
            if(isnan(YAxis(set).limits[0])) o << "*";
            else o << YAxis(set).limits[0];
            o << ":";
            if(isnan(YAxis(set).limits[1])) o << "*";
            else o << YAxis(set).limits[1];
            o << "]\n";
        }


        if( set && d[set].m_Xaxis.name != d[0].m_Xaxis.name)
            setstr = to_string(set+1);
        else setstr = "";
        o << "set x" << setstr << "label '" << XAxis(set).name << "' \n";

        if( set && d[set].m_Yaxis.name != d[0].m_Yaxis.name)
            setstr = to_string(set+1);
        else setstr = "";
        o << "set y" << setstr << "label '" << YAxis(set).name << "' \n";
    }
}


void Plot2D::print_plot_style1(const std::string &name, std::ofstream &o) const {
    // TERMINAL //
    o << "set terminal postscript eps enhanced color font 'Helvetica,20' \n";
    o << "set output '" << name+".eps" << "' \n";

    // TODO: REMOVE !!!!
    std::vector<CurveType> m_curves = vector_cat(d[0].m_curves, d[1].m_curves);
    std::vector<OptionFlags> m_curves_flags = vector_cat(d[0].m_curves_flags, d[1].m_curves_flags);

    // CURVE STYLES //
    int count = 0;
    foreach (const Curve2D &curve, m_curves) {
        (void)curve;
        const ColorRGB &color = s_chart_colors->ColorList().at(count).color;
        o << "set style line " << count+1 << " lc rgb '" << color.ToString()
          << "' lt 1 lw 4 pt 7 ps 1.3" << std::endl;
        count ++;
    }

    if(m_curves.size() == 1) o << "set key off \n";
    else o << "set key below \n";

    o << "set grid \n";

    // LABELS //
    std::string title = this->GetName();
    if(!m_subtitle.empty()) title += "\\n{/*0.5 " + m_subtitle + "}";
    o << "set title \"" << title << "\" font 'Helvetica,25' \n";

    // RANGES //
    this->print_plot_range(o);

    // CURVES //
    count=0;
    for (int set = 0; set < SET_SIZE; ++set) {
        m_curves = d[set].m_curves;
        m_curves_flags = d[set].m_curves_flags;
        foreach (const Curve2D &curve, m_curves) {
            const OptionFlags &flags = m_curves_flags[count];

            // PLOT COMMAND and go new line ! //
            if(count==0) o << "plot \"" << name+".dat" << "\" \\\n    ";
            else o << ", \\\n  ''";

            // MULTIAXES //
            std::string axes = " ";
            if(set > 0) {
                axes += " axes ";
                axes += (d[set].m_Xaxis == d[0].m_Xaxis) ? "x1" : "x"+to_string(set+1);
                axes += (d[set].m_Yaxis == d[0].m_Yaxis) ? "y1" : "y"+to_string(set+1);
            }

            // SMOOTH //
            bool has_errors = 0;
            foreach (const Point2D &pt, curve.Points())
                has_errors |= !are_same(pt(2),.0);
            std::string smooth = (flags.testFlag(Smoothed) && curve.Points().size()>4
                                  && has_errors) ? " smooth acsplines" : " ";

            if( flags.testFlag(ShowPoints) && !flags.testFlag(ShowLines) ) {
                o << " index " << count << " using 1:2:3"
                  << axes
                  << " title \"" << curve.GetName() << "\""
                  << " w yerrorbars ls " << count+1;
            }
            else if ( !flags.testFlag(ShowPoints) && flags.testFlag(ShowLines) ) {
                o << " index " << count << " using 1:2:3"
                  << axes
                  << smooth
                  << " title  \"" << curve.GetName() << "\""
                  << " w lines ls " << count+1;
            }
            else if(has_errors) {
                o << " index " << count << " using 1:2:3"
                  << axes
                  << " title \"" << curve.GetName() << "\""
                  << " w yerrorbars ls " << count+1

                  << ", \\\n  ''"
                  << " index " << count << " using 1:2:3 "
                  << axes
                  << smooth
                  << " notitle w lines ls " << count+1;
            }
            else {
                o << " index " << count << " using 1:2:3"
                  << axes
                  << smooth
                  << " title  \"" << curve.GetName() << "\""
                  << " w lines ls " << count+1;
            }
            count++;
        }
    }
    o << std::endl;
}



//set terminal pdf enhanced color solid size 6,4
//#font 'Helvetica,20'
//# set size 1.4,1.4
//set bmargin 5.5
//# set lmargin {<margin>}
//# set rmargin {<margin>}
//# set tmargin {<margin>}
//set output 'size-udt.pdf'
//set style fill transparent solid 0.5 noborder
//set style line 1 lc rgb '#104e8b' lw 4 pt 0 ps 1.3 dashtype 1
//set style line 2 lc rgb '#cd5c5c' lw 4 pt 7 ps 1.3 dashtype 2
//set style line 3 lc rgb '#388e8e' lw 4 pt 7 ps 1.3 dashtype 3
//set style line 4 lc rgb '#da70d6' lw 4 pt 7 ps 1.3 dashtype 4
//set style line 5 lc rgb '#70aeeb' lw 0
//set style line 6 lc rgb '#fd9c9c' lw 0
//set style line 7 lc rgb '#98eeff' lw 0
//set style line 8 lc rgb '#fad0f6' lw 0
//set key below
//set grid
//# set title "Throughput vs Segment Size in tcp\n{/*0.5 (local time: 2016-06-02.00:11:10) recstg01  -->  150.178.101.7}" font 'Helvetica,25'
//set xlabel 'Segment size [KB] of signal data'
//set ylabel 'Total speed [MB/s]'


void Plot2D::print_plot_style2(const std::string &name, std::ofstream &o) const
{
    // TERMINAL //
    o << "set terminal pdf enhanced color solid size 6,4 \n";
    o << "#font 'Helvetica,20' \n";
    o << "set bmargin 5.5 \n";
    o << "# set lmargin {<margin>} \n";
    o << "# set rmargin {<margin>} \n";
    o << "# set tmargin {<margin>} \n";
    o << "set output '" << name+".pdf" << "' \n";
    o << "set style fill transparent solid 0.5 noborder" << "\n";

    // TODO: REMOVE !!!!
    std::vector<CurveType> m_curves = vector_cat(d[0].m_curves, d[1].m_curves);
    std::vector<OptionFlags> m_curves_flags = vector_cat(d[0].m_curves_flags, d[1].m_curves_flags);

    // CURVE STYLES //
    int count = 0;
    foreach (const Curve2D &curve, m_curves) {
        (void)curve;
        const ColorRGB &color = s_chart_colors->ColorList().at(count).color;
        o << "set style line " << count+1 << " lc rgb '" << color.ToString()
          << "' lw 4 pt " << ((count==0)?0:7) << " "
          << "ps 1.3 " << "dashtype " << (count%4)+1 << "\n";
        count ++;
    }

    if(m_curves.size() == 1) o << "set key off \n";
    else o << "set key below \n";

    o << "set grid \n";

    // LABELS //
    std::string title = this->GetName();
    if(!m_subtitle.empty()) title += "\\n{/*0.5 " + m_subtitle + "}";
    o << "set title \"" << title << "\" font 'Helvetica,25' \n";

    // RANGES //
    this->print_plot_range(o);

    // CURVES //
    count=0;
    for (int set = 0; set < SET_SIZE; ++set) {
        m_curves = d[set].m_curves;
        m_curves_flags = d[set].m_curves_flags;
        foreach (const Curve2D &curve, m_curves) {
            const OptionFlags &flags = m_curves_flags[count];

            if(count==0) o << "plot \"" << name+".dat" << "\"";
            else o << ", \\\n  ''";

            // MULTIAXES //
            std::string axes = " ";
            if(set > 0) {
                axes += " axes ";
                axes += (d[set].m_Xaxis == d[0].m_Xaxis) ? "x1" : "x"+to_string(set+1);
                axes += (d[set].m_Yaxis == d[0].m_Yaxis) ? "y1" : "y"+to_string(set+1);
            }

            // SMOOTH //
            bool has_errors = 0;
            foreach (const Point2D &pt, curve.Points())
                has_errors |= !are_same(pt(2),.0);
            std::string smooth = (flags.testFlag(Smoothed) && curve.Points().size()>4
                                  && has_errors) ? " smooth acsplines" : " ";

            // CONFIDENCE //
            std::string c_lo = "($2-1.96*$3/sqrt(30))";
            std::string c_hi = "($2+1.96*$3/sqrt(30))";

            if( flags.testFlag(ShowPoints) && !flags.testFlag(ShowLines) ) {
                o << " index " << count << " using 1:" << c_lo << ":" << c_hi
                  << axes
                  << " title \"" << curve.GetName() << "\" "
                  << " w yerrorbars ls " << count+1;
            }
            else if ( !flags.testFlag(ShowPoints) && flags.testFlag(ShowLines) ) {
                o << " index " << count << " using 1:2:3 "
                  << axes
                  << " title  \"" << curve.GetName() << "\" "
                  << smooth << " w lines ls " << count+1;
            }
            else if(has_errors) {
                o << " index " << count << " using 1:" << c_lo << ":" << c_hi
                  << axes
                  << " notitle "
                  << " w filledcurves ls " << count+1
                  << " fs transparent pattern 2 "

                     // lines //
                  << ", \\\n  ''"
                  << " index " << count << " using 1:2:3 "
                  << axes
                  << smooth
                  << " title \"" << curve.GetName() << "\" "
                  << " w lines ls " << count+1;
            }
            else {
                o << " index " << count << " using 1:2:3"
                  << axes
                  << smooth
                  << " title  \"" << curve.GetName() << "\" "
                  << " w lines ls " << count+1;
            }
            count++;
        }
    }
    o << std::endl;
}


void Plot2D::PrintToGnuplotFile(std::string file_name, enum GnuplotStyle style) const
{
           const char sep = '\t';
           if(file_name.empty()) file_name = this->GetName();
           assert(!file_name.empty());

           std::string dat_file = file_name + ".dat";
           std::string plt_file = file_name + ".plt";
           std::string eps_file = file_name + ".eps";

           // TODO: REMOVE !!!!
           std::vector<CurveType> m_curves = vector_cat(d[0].m_curves, d[1].m_curves);
           std::vector<OptionFlags> m_curves_flags = vector_cat(d[0].m_curves_flags, d[1].m_curves_flags);

           if(m_curves.empty()) throw std::logic_error("No curves to plot");

           ////////////////////////////////////////////////////////////////////////////////
           //  CURVE DATA  ////////////////////////////////////////////////////////////////
           ////////////////////////////////////////////////////////////////////////////////

           std::ofstream o;
           o.open( dat_file.c_str() );
           assert(o.is_open());
           foreach (const Curve2D &curve, m_curves) {
               std::string name = curve.GetName();
               if(name.empty()) name = "X";
               o << "# " << name << sep << "Y" << sep << "RMS" <<  std::endl;
               foreach (const Curve2D::Point pt, curve.Points()) {
                   o << pt(0) << sep << pt(1) << sep << pt(2) <<  std::endl;
               }
               o <<  std::endl << std::endl;
           }
           o.close();

           ////////////////////////////////////////////////////////////////////////////////
           //  PLOT DATA  /////////////////////////////////////////////////////////////////
           ////////////////////////////////////////////////////////////////////////////////

           o.open( plt_file.c_str() );
           assert(o.is_open());

           switch (style) {
           case mdsip_test::Plot2D::GnuplotStyle1:
               print_plot_style1(file_name, o);
               break;
           case mdsip_test::Plot2D::GnuplotStyle2:
               print_plot_style2(file_name, o);
               break;
           default:
               print_plot_style1(file_name, o);
               break;
           }

           o.close();
}








} // mdsip_test
