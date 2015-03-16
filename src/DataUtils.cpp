#include "DataUtils.h"

#include "stdio.h"

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


void Plot2D::PrintToCsv(std::ostream &o, const char sep)
{
    typedef std::vector<PointType>::iterator ItrType;
    std::vector<ItrType> itr,itr_end;
    o << "X";
    foreach (Curve2D &curve, m_curves) {
        curve.Update();
        if(curve.Size()) {
            o << sep << curve.GetName() << sep << curve.GetName()+"_err";
            itr.push_back( curve.Points().begin() );
            itr_end.push_back( curve.Points().end() );
        }
    }
    o << std::endl;

    // TODO: find a better implementation //
    for(itr; itr != itr_end;) {
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
}

void Plot2D::PrintToCsv(std::string file_name, const char sep)
{
    std::ofstream file;
    file.open(std::string(file_name+".csv").c_str());
    assert(file.is_open());
    this->PrintToCsv(file,sep);
    file.close();
}



void Plot2D::PrintToGnuplotFile(std::string file_name) const
{
           const char sep = '\t';
           if(file_name.empty()) file_name = this->GetName();
           assert(!file_name.empty());

           std::string dat_file = file_name + ".dat";
           std::string plt_file = file_name + ".plt";
           std::string eps_file = file_name + ".eps";

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

           // TERMINAL //
           o << "set terminal postscript eps enhanced color font 'Helvetica,20' \n";
           o << "set output '" << eps_file << "' \n";

           // CURVE STYLES //
           int count = 0;
           foreach (const Curve2D &curve, this->m_curves) {
               (void)curve;
               const ColorRGB &color = s_chart_colors->ColorList().at(count).color;
               o << "set style line " << count+1 << " lc rgb '" << color.ToString()
                 << "' lt 1 lw 4 pt 7 ps 1.3" << std::endl;
               count ++;
           }

           if(this->m_curves.size() == 1) o << "set key off \n";
           else o << "set key below \n";

           o << "set grid \n";

           // LABELS //
           std::string title = this->GetName();
           if(!m_subtitle.empty()) title += "\\n{/*0.5 " + m_subtitle + "}";
           o << "set title \"" << title << "\" font 'Helvetica,25' \n";
           o << "set xlabel '" << XAxis().name << "' \n";
           o << "set ylabel '" << YAxis().name << "' \n";

           // RANGES //
           if(!are_same(XAxis().limits[0],XAxis().limits[1]) )
               o << "set xrange [" << XAxis().limits[0] <<":"<< XAxis().limits[1] << "]\n";
           if(!are_same(YAxis().limits[0],YAxis().limits[1]) )
               o << "set yrange [" << YAxis().limits[0] <<":"<< YAxis().limits[1] << "]\n";

           // CURVES //
           count=0;
           foreach (const Curve2D &curve, this->m_curves) {
               const OptionFlags &flags = m_curves_flags[count];

               if(count==0) o << "plot \"" << file_name+".dat" << "\"";
               else o << ", \\\n  ''";

               bool has_errors = 0;
               foreach (const Point2D &pt, curve.Points())
                   has_errors |= !are_same(pt(2),.0);

               std::string smooth = (flags.testFlag(Smoothed) && curve.Points().size()>4 && has_errors) ? "smooth acsplines" : "";

               if( flags.testFlag(ShowPoints) && !flags.testFlag(ShowLines) ) {
                   o << " index " << count << " using 1:2:3  title \"" << curve.GetName() << "\" w yerrorbars ls " << count+1;
               }
               else if ( !flags.testFlag(ShowPoints) && flags.testFlag(ShowLines) ) {
                   o << " index " << count << " using 1:2:3 title  \"" << curve.GetName() << "\" " << smooth << " w lines ls " << count+1;
               }
               else if(has_errors) {
                   o << " index " << count << " using 1:2:3  title \"" << curve.GetName() << "\" w yerrorbars ls " << count+1 << " , \\\n  ''"
                     << " index " << count << " using 1:2:3 " << smooth << " notitle w lines ls " << count+1;
               }
               else {
                   o << " index " << count << " using 1:2:3 title  \"" << curve.GetName() << "\" " << smooth << " w lines ls " << count+1;
               }
               count++;
           }
           o << std::endl;

           o.close();
}










