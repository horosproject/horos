/*=========================================================================
 
 vtkPowerCrustSurfaceReconstruction algorithm reconstructs surfaces from
 unorganized point data.
 Copyright (C) 2014  Arash Akbarinia, Tim Hutton, Bruce Lamond
 Dieter Pfeffer, Oliver Moss
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 =========================================================================*/

#include "vtkPowerCrustSurfaceReconstruction.h"

#include <VTK/vtkCellArray.h>
#include <VTK/vtkFloatArray.h>
#include <VTK/vtkInformation.h>
#include <VTK/vtkInformationVector.h>
#include <VTK/vtkObjectFactory.h>
#include <VTK/vtkPointData.h>

#include <assert.h>
#include <float.h>

//=====================================================================

class vtkPowerCrustSurfaceReconstructionException : public std::exception
{
    
public:
    vtkPowerCrustSurfaceReconstructionException ( const char* m = "vtkPowerCrustSurfaceReconstructionException!" ) : msg ( m ) { }
    ~vtkPowerCrustSurfaceReconstructionException() throw() {}
    virtual const char* what() const throw()
    {
        return msg;
    }
    
private:
    const char* msg;
    
};

//=====================================================================

typedef double Coord;
typedef Coord* point;
typedef point site;

#define MAXBLOCKS 10000
#define Nobj      10000

#define STORAGE_GLOBALS(X)    \
\
extern size_t X##_size;      \
extern X *X##_list;      \
extern X *new_block_##X(int);    \
void free_##X##_storage(void);    \

#define INCP(X,p,k) ((X*) ( (char*)p + (k) * X##_size)) /* portability? */

#define STORAGE(X)            \
\
size_t  X##_size;            \
X  *X##_list = 0;            \
\
X *new_block_##X(int make_blocks)        \
{  int i;              \
static  X *X##_block_table[MAXBLOCKS];      \
X *xlm, *xbt;          \
static int num_##X##_blocks;        \
if (make_blocks) {          \
assert(num_##X##_blocks<MAXBLOCKS);    \
DEB(0, before) DEBEXP(0, Nobj * X##_size)      \
\
xbt = X##_block_table[num_##X##_blocks++] =  (X*)malloc(Nobj * X##_size); \
memset(xbt,0,Nobj * X##_size);  \
if (!xbt) {          \
DEBEXP(-10,num_##X##_blocks)    \
}            \
assert(xbt);          \
\
xlm = INCP(X,xbt,Nobj);        \
for (i=0;i<Nobj; i++) {        \
xlm = INCP(X,xlm,(-1));      \
xlm->next = X##_list;      \
X##_list = xlm;        \
}            \
\
return X##_list;        \
}              \
\
for (i=0; i<num_##X##_blocks; i++)      \
free(X##_block_table[i]);      \
num_##X##_blocks = 0;          \
X##_list = 0;            \
return 0;            \
}                \
\
void free_##X##_storage(void) {new_block_##X(0);}    \
/*end of STORAGE*/

#define NEWL(X,p)            \
{                \
p = X##_list ? X##_list : new_block_##X(1);    \
assert(p);            \
X##_list = p->next;          \
}                \

#define NEWLRC(X,p)            \
{                \
p = X##_list ? X##_list : new_block_##X(1);    \
assert(p);            \
X##_list = p->next;          \
p->ref_count = 1;          \
}                \

#define FREEL(X,p)            \
{                \
memset((p),0,X##_size);          \
(p)->next = X##_list;          \
X##_list = p;            \
}                \

#define dec_ref(X,v)  {if ((v) && --(v)->ref_count == 0) FREEL(X,(v));}
#define inc_ref(X,v)  {if (v) v->ref_count++;}
#define NULLIFY(X,v)  {dec_ref(X,v); v = NULL;}

#define mod_refs(op,s)          \
{              \
int i;            \
neighbor *mrsn;          \
\
for (i=-1,mrsn=s->neigh-1;i<cdim;i++,mrsn++)  \
op##_ref(basis_s, mrsn->basis);    \
}

#define copy_simp(new,s)      \
{  NEWL(simplex,new);      \
memcpy(new,s,simplex_size);    \
mod_refs(inc,s);      \
}            \

#define DEBS(qq)  {if (DEBUG>qq) {
#define EDEBS }}
#define DEBOUT 0
#define DEB(ll,mes)  DEBS(ll) if(DEBOUT){fprintf(DEBOUT,#mes "\n");fflush(DEBOUT);} EDEBS
#define DEBEXP(ll,exp) DEBS(ll) if(DEBOUT){fprintf(DEBOUT,#exp "=%G\n", (double) exp); fflush(DEBOUT);} EDEBS

#define MAXDIM 8
#define BLOCKSIZE 100000
#define DEBUG -7

#define EXACT 1 /* sunghee */

#define CNV 0 /* sunghee : status of simplex, if it's on convex hull */
#define VV 1 /* sunghee :    if it's regular simplex  */
#define SLV -1 /* sunghee : if orient3d=0, sliver simplex */
#define AV 2 /* if av contains the averaged pole vector */
#define POLE_OUTPUT 3 /* VV is pole and it's ouput */
#define SQ(a) ((a)*(a)) /* sunghee */

#define BAD_POLE -1

// next two lines added by TJH to avoid name collision
#undef IN
#undef OUT

#define IN 2
#define OUT 1
#define INIT 0

#define NO 1

#define FIRST_EDGE 0
#define POW 1
#define VISITED 3

#define VALIDEDGE 24
#define ADDAXIS 13

/* for priority queue */
#define LEFT(i)   ((i) * 2)
#define RIGHT(i)  ((i) * 2 + 1)
#define PARENT(i) ((i) / 2)

typedef struct basis_s
{
    struct basis_s *next; /* free list */
    int ref_count;  /* storage management */
    int lscale;    /* the log base 2 of total scaling of vector */
    Coord sqa, sqb; /* sums of squared norms of a part and b part */
    Coord vecs[1]; /* the actual vectors, extended by malloc'ing bigger */
} basis_s;

typedef struct neighbor
{
    site vert; /* vertex of simplex */
    /*        short edgestatus[3];  FIRST_EDGE if not visited
     NOT_POW if not dual to powercrust faces
     POW if dual to powercrust faces */
    struct simplex *simp; /* neighbor sharing all vertices but vert */
    basis_s *basis; /* derived vectors */
} neighbor;

typedef struct simplex
{
    simplex() : isVvNull ( false ) {}
    simplex *next;   /* used in free list */
    short mark;
    double vv[3];
    bool isVvNull;
    double sqradius; /* squared radius of Voronoi ball */
    short status;/* sunghee : 0(CNV) if on conv hull so vv contains normal vector;
                  1(VV) if vv points to circumcenter of simplex;
                  -1(SLV) if cond=0 so vv points to hull
                  2(AV) if av contains averaged pole */
    long poleindex; /* for 1st DT, if status==POLE_OUTPUT, contains poleindex; for 2nd, contains vertex index for powercrust output for OFF file format */
    short edgestatus[6]; /* edge status :(01)(02)(03)(12)(13)(23)
                          FIRST_EDGE if not visited
                          VISITED
                          NOT_POW if not dual to powercrust faces
                          POW if dual to powercrust faces */
    /*  short tristatus[4];   triangle status :
     FIRST if not visited
     NO   if not a triangle
     DEG  if degenerate triangle
     SURF if surface triangle
     NORM if fails normal test
     VOR  if falis voronoi edge test
     VOR_NORM if fails both test */
    /* NOTE!!! neighbors has to be the LAST field in the simplex stucture,
     since it's length gets altered by some tricky Clarkson-move.
     Also peak has to be the one before it.
     Don't try to move these babies!! */
    long visit;     /* number of last site visiting this simplex */
    basis_s* normal;    /* normal vector pointing inward */
    neighbor peak;      /* if null, remaining vertices give facet */
    neighbor neigh[1];  /* neighbors of simplex */
} simplex;

/* structure for list of opposite poles, opplist. */
typedef struct plist
{
    long pid;
    double angle;
    plist *next;
} plist;

/* regular triangulation edge, between pole pid to center of simp? */
typedef struct edgesimp
{
    short kth;
    double angle;   /* angle between balls */
    simplex *simp;
    long pid;
    edgesimp *next;
} edgesimp;

/* additional info about poles: label for pole, pointer to list of regular
 triangulation edges, squared radius of  polar ball. adjlist is an
 array of polelabels. */
typedef struct polelabel
{
    edgesimp *eptr;
    short bad;
    short label;
    double in; /* 12/7/99 Sunghee for priority queue */
    double out; /* 12/7/99 Sunghee for priority queue */
    int hid; /* 0 if not in the heap, otherwise heap index 1..heap_size*/
    double sqradius;
    double oppradius; /* minimum squared radius of this or any opposite ball */
    double samp_distance;
    int grafindex; /* index in thinning graph data structure */
} polelabel;

typedef struct fg_node fg;
typedef struct tree_node Tree;
struct tree_node
{
    Tree *left, *right;
    site key;
    int size;   /* maintained to be the number of nodes rooted here */
    fg *fgs;
    Tree *next; /* freelist */
};

typedef struct fg_node
{
    Tree *facets;
    double dist, vol;   /* of Voronoi face dual to this */
    fg *next;       /* freelist */
    short mark;
    int ref_count;
} fg_node;

typedef struct heap_array
{
    int pid;
    double pri;
} heap_array;

STORAGE_GLOBALS ( basis_s )
STORAGE_GLOBALS ( fg )
STORAGE_GLOBALS ( Tree )
STORAGE_GLOBALS ( simplex )
STORAGE ( basis_s )
STORAGE ( fg )
STORAGE ( Tree )
STORAGE ( simplex )

//=====================================================================

class vtkPowerCrustSurfaceReconstructionImpl
{
    
private:
    
    typedef void* ( vtkPowerCrustSurfaceReconstructionImpl::*visit_func ) ( simplex *, void * );
    typedef int ( vtkPowerCrustSurfaceReconstructionImpl::*test_func ) ( simplex *, int, void * );
    
    void ASSERT ( int b, const char* message = "" );
    
    int pcFALSE;
    int pcTRUE;
    
    site p;
    std::vector<point> site_blocks;
    std::vector<point> site_blocks_pointers;
    int num_blocks;
    int pdim;
    
    Coord infinity[10]; /* point at infinity for Delaunay triang */
    
    int rdim,   /* region dimension: (max) number of sites specifying region */
    cdim,   /* number of sites currently specifying region */
    site_size; /* size of malloc needed for a site */
    
    site get_site_offline ( long );
    
    double bound[8][3];
    double mult_up;
    Coord mins[MAXDIM];
    Coord maxs[MAXDIM];
    double Huge;
    
    void read_bounding_box ( long );
    void construct_face ( simplex *, short );
    void compute_distance ( simplex**, int, double* );
    
#define MAXPOINTS 10000
    short mi[MAXPOINTS], mo[MAXPOINTS];
    int correct_orientation ( double*,double*,double*,double*,double* );
    
#ifndef _RAND48_H_
#define _RAND48_H_
    
    void _dorand48 ( unsigned short xseed[3] );
    
#define  RAND48_MULT_0  (0xe66d)
#define  RAND48_MULT_1  (0xdeec)
#define  RAND48_MULT_2  (0x0005)
#define  RAND48_ADD  (0x000b)
    
#endif /* _RAND48_H_ */
    
    double omaxs[3], omins[3];  /* 8 vertices for bounding box */
    int num_vtxs;
    int num_poles;
    
    /* Data structures for poles */
    simplex **pole1, **pole2;  /* arrays of poles - per sample*/
    std::vector<polelabel> adjlist;
    std::vector<plist*> opplist;
    double* lfs_lb;  /*  array of lower bounds for lfs of each sample */
    double est_r;   /* estimated value of r - user input */
    
    double *pole1_distance, *pole2_distance;
    
    /* for priority queue */
    int heap_size;
    
    int scount;
    int v1[6];
    int v2[6];
    int v3[6];
    int v4[6];
    long num_sites;
    
    short vd_new;
    
    short power_diagram; /* 1 if power diagram */
    
    int dim;
    long s_num; /* site number */
    
    double theta; /* input argument - angle defining deep intersection */
    double deep; /* input argument.. same as theta for labeling unlabled pole */
    
    long site_numm ( site p );
    
    site new_site ( site p, long j );
    
    // TJH: trying to replace file use
    site vtk_read_next_site ( long j );
    site vtk_pole_read_next_site ( long j );
    
    std::vector<long> shufmat;
    long mat_size; // EPRO set to global to reinitialize
    
    void make_shuffle ( void );
    
    long shufflef ( long i );
    
    long ( vtkPowerCrustSurfaceReconstructionImpl::*shuf ) ( long );
    long ( vtkPowerCrustSurfaceReconstructionImpl::*site_num ) ( site );
    site ( vtkPowerCrustSurfaceReconstructionImpl::*get_site ) ( );
    site ( vtkPowerCrustSurfaceReconstructionImpl::*get_site_n ) ( long );
    
    site get_next_site ( void );
    
    void make_output ( simplex *root, void * ( vtkPowerCrustSurfaceReconstructionImpl::*visit_gen ) ( simplex*, visit_func ), visit_func visit );
    
    neighbor p_neigh; // EPRO added set to global
    basis_s *seesB;
    simplex **st_search;
    simplex **st_visit_triang_gen;
    
    basis_s *check_perps_b;
    
#define swap_points(a,b) {point t; t=a; a=b; b=t;}
    
    double alpha_test_alpha;
    
    /* variables for tracking infinite loop */
    /* (This should never occur, but it did in early versions) */
    int loopStart;
    int count;
    int lastCount;
    
#define compare(i,j) (( this->*site_num )(i)-( this->*site_num )(j))
    
#define node_size(x) ((x) ? ((x)->size) : 0 )
    
    heap_array *heap_A;
    int heap_length;
    long pnum;
    
#define push(x, st, tms) *(st + tms++) = x;
#define pop(x, st, tms)  x = *(st + --tms);
    
    long visit_triang_gen_vnum;
    long visit_triang_gen_ss;
    simplex *make_facets_ns;
    long search_ss;
    
    simplex *ch_root;
    
#define NEARZERO(d) ((d) < FLT_EPSILON && (d) > -FLT_EPSILON)
    
#define SWAP(X,a,b) {X t; t = a; a = b; b = t;}
    
#define DELIFT 0
    int basis_vec_size;
    
    int exact_bits;
    float b_err_min, b_err_min_sq;
    
    short vd;
    basis_s tt_basis;
    basis_s *tt_basisp;
    basis_s *infinity_basis;
    
#define VA(x) ((x)->vecs+rdim)
#define VB(x) ((x)->vecs)
    
#define two_to(x) ( ((x)<20) ? 1<<(x) : ldexp(1.0,(x)) )  // EPRO added
    
    int sc_lscale;
    double sc_max_scale, sc_ldetbound, sc_Sb;
    
    Coord Vec_dot ( point x, point y );
    
    Coord Vec_dot_pdim ( point x, point y );
    
    Coord Norm2 ( point x );
    
    void Ax_plus_y ( Coord a, point x, point y );
    
    void Ax_plus_y_test ( Coord a, point x, point y );
    
    void Vec_scale_test ( int n, Coord a, Coord *x );
    
    double sc ( basis_s *v,simplex *s, int k, int j );
    
    int reduce_inner ( basis_s *v, simplex *s, int k );
    
    void trans ( point z, point p, point q );
    
#define lift(z,s) {if (vd) z[2*rdim-1] =z[rdim-1]= ldexp(Vec_dot_pdim(z,z), -DELIFT);}
    
    int reduce ( basis_s **v, point p, simplex *s, int k );
    
    void get_basis_sede ( simplex *s );
    
    int out_of_flat ( simplex *root, point p );
    
    double cosangle_sq ( basis_s* v,basis_s* w );
    
    int check_perps ( simplex *s );
    
    void get_normal_sede ( simplex *s );
    
    void get_normal ( simplex *s );
    
    int sees ( site p, simplex *s );
    
    double radsq ( simplex *s );
    
    void* zero_marks ( simplex* s, void* dum );
    void* one_marks ( simplex* s, void* dum );
    void* conv_facetv ( simplex* s, void* dum );
    void* mark_points ( simplex* s, void* dum );
    
    int alph_test ( simplex *s, int i, void *alphap );
    
    void* visit_outside_ashape ( simplex *root, visit_func visit );
    
    int check_ashape ( simplex *root, double alpha );
    
    simplex *build_convex_hull ( short dim, short vdd );
    
    void free_hull_storage ( void );
    
    void *compute_vv ( simplex *s, void *p );
    void *compute_pole2 ( simplex *s, void *p );
    void *compute_3d_power_vv ( simplex *s, void *p );
    void *compute_axis ( simplex *s, void *p );
    
    int close_pole ( double* v, double* p, double lfs_lb );
    
    int antiLabel ( int label );
    
    /* computes angle between two opposite poles */
    double computePoleAngle ( simplex* pole1, simplex* pole2, double* samp );
    
    /* Adds a new pair of opposite poles to each other's lists */
    void newOpposite ( int p1index, int p2index, double pole_angle );
    
    /* Outputs a pole, saving it's squared radius in adjlist */
    void outputPole ( simplex* pole, int poleid, double* samp, int* num_poles,double distance );
    
    /* Splay using the key i (which may or may not be in the tree.) */
    /* The starting root is t, and the tree used is defined by rat  */
    /* size fields are maintained */
    Tree * splay ( site i, Tree *t );
    
    Tree * insert ( site i, Tree * t );
    
    void free_heap ();
    void init_heap ( int num );
    
    void heapify ( int hi );
    
    int extract_max();
    
    int insert_heap ( int pi, double pr );
    
    /* make the element heap_A[hi].pr = pr ... */
    void update ( int hi, double pr );
    
    void *visit_triang_gen ( simplex *s, visit_func visit, test_func test );
    
    int truet ( simplex *s, int i, void *dum );
    
    void *visit_triang ( simplex *root, visit_func visit );
    
    int hullt ( simplex *s, int i, void *dummy );
    
    void *facet_test ( simplex *s, void *dummy );
    
    /* visit all simplices with facets of the current hull */
    void *visit_hull ( simplex *root, visit_func visit );
    
#define lookup(a, b, what)                      \
{                                   \
int i;                              \
neighbor *x;                            \
for (i = 0, x = a->neigh; (x->what != b) && (i < cdim) ; i++, x++); \
if (i < cdim)                         \
return x;                       \
else {                              \
ASSERT(pcFALSE, "adjacency failure!");                        \
return 0;                       \
}                               \
}                                   \

    neighbor *op_simp ( simplex *a, simplex *b );
    
    neighbor *op_vert ( simplex *a, site b );
    
    void connect ( simplex *s );
    
    simplex *make_facets ( simplex *seen );
    
    simplex *extend_simplices ( simplex *s );
    
    simplex *search ( simplex *root );
    
    point get_another_site ( void );
    
    void buildhull ( simplex *root );
    
    int propagate();
    
    void opp_update ( int pi );
    
    void sym_update ( int pi );
    
    void update_pri ( int hi, int pi );
    
    void label_unlabeled ( int num );
    
    double sqdist ( double a[3], double b[3] );
    
    void dir_and_dist ( double a[3], double b[3], double dir[3], double* dist );
    void tetcircumcenter ( double a[3], double b[3], double c[3], double d[3], double circumcenter[3], double *cond );
    void tetorthocenter ( double a[4], double b[4], double c[4], double d[4], double orthocenter[3], double *cnum );
    
#define INEXACT                          /* Nothing */
    
#define REAL double                      /* float or double */
    
#define Absolute(a)  ((a) >= 0.0 ? (a) : -(a))
    
#define Fast_Two_Sum_Tail(a, b, x, y) \
bvirt = x - a; \
y = b - bvirt
    
#define Fast_Two_Sum(a, b, x, y) \
x = (REAL) (a + b); \
Fast_Two_Sum_Tail(a, b, x, y)
    
#define Two_Sum_Tail(a, b, x, y) \
bvirt = (REAL) (x - a); \
avirt = x - bvirt; \
bround = b - bvirt; \
around = a - avirt; \
y = around + bround
    
#define Two_Sum(a, b, x, y) \
x = (REAL) (a + b); \
Two_Sum_Tail(a, b, x, y)
    
#define Two_Diff_Tail(a, b, x, y) \
bvirt = (REAL) (a - x); \
avirt = x + bvirt; \
bround = bvirt - b; \
around = a - avirt; \
y = around + bround
    
#define Two_Diff(a, b, x, y) \
x = (REAL) (a - b); \
Two_Diff_Tail(a, b, x, y)
    
#define Split(a, ahi, alo) \
c = (REAL) (splitter * a); \
abig = (REAL) (c - a); \
ahi = c - abig; \
alo = a - ahi
    
#define Two_Product_Tail(a, b, x, y) \
Split(a, ahi, alo); \
Split(b, bhi, blo); \
err1 = x - (ahi * bhi); \
err2 = err1 - (alo * bhi); \
err3 = err2 - (ahi * blo); \
y = (alo * blo) - err3
    
#define Two_Product(a, b, x, y) \
x = (REAL) (a * b); \
Two_Product_Tail(a, b, x, y)
    
    /* Two_Product_Presplit() is Two_Product() where one of the inputs has       */
    /*   already been split.  Avoids redundant splitting.                        */
    
#define Two_Product_Presplit(a, b, bhi, blo, x, y) \
x = (REAL) (a * b); \
Split(a, ahi, alo); \
err1 = x - (ahi * bhi); \
err2 = err1 - (alo * bhi); \
err3 = err2 - (ahi * blo); \
y = (alo * blo) - err3
    
    /* Macros for summing expansions of various fixed lengths.  These are all    */
    /*   unrolled versions of Expansion_Sum().                                   */
    
#define Two_One_Diff(a1, a0, b, x2, x1, x0) \
Two_Diff(a0, b , _i, x0); \
Two_Sum( a1, _i, x2, x1)
    
#define Two_Two_Diff(a1, a0, b1, b0, x3, x2, x1, x0) \
Two_One_Diff(a1, a0, b0, _j, _0, x0); \
Two_One_Diff(_j, _0, b1, x3, x2, x1)
    
#define Two_One_Product(a1, a0, b, x3, x2, x1, x0) \
Split(b, bhi, blo); \
Two_Product_Presplit(a0, b, bhi, blo, _i, x0); \
Two_Product_Presplit(a1, b, bhi, blo, _j, _0); \
Two_Sum(_i, _0, _k, x1); \
Fast_Two_Sum(_j, _k, x3, x2)
    
    REAL splitter;     /* = 2^ceiling(p / 2) + 1.  Used to split floats in half. */
    REAL epsilon;                /* = 2^(-p).  Used to estimate roundoff errors. */
    /* A set of coefficients used to calculate maximum roundoff errors.          */
    REAL resulterrbound;
    REAL ccwerrboundA, ccwerrboundB, ccwerrboundC;
    REAL o3derrboundA, o3derrboundB, o3derrboundC;
    
    void exactinit();
    
    int fast_expansion_sum_zeroelim ( int elen,REAL *e,int flen,REAL *f,REAL *h );
    
    int scale_expansion_zeroelim ( int elen,REAL *e,REAL b,REAL *h );
    
    REAL estimate ( int elen, REAL *e );
    
    REAL orient2dadapt ( REAL* pa, REAL* pb, REAL* pc, REAL detsum );
    REAL orient3dadapt ( REAL* pa, REAL* pb, REAL* pc, REAL* pd, REAL permanent );
    REAL orient3d ( REAL* pa, REAL* pb, REAL* pc, REAL* pd );
    
    unsigned short X[3];
    
    double double_rand ( void );
    
    void init_rand ( void );
    
    double logb ( double x );
    
    double local_erand48 ( unsigned short xseed[3] ) throw();
    
    unsigned short _rand48_mult[3];
    unsigned short _rand48_add;
    
    
    
public:
    vtkPowerCrustSurfaceReconstructionImpl ( void );
    
    void pcInit();
    
    void freeAll ( void );
    
    void adapted_main ( double m_mult_up );
    
    // these globals are here so we can access them from anywhere in the powercrust code
    // if you can find a neat way to improve this then please feel free
    vtkPolyData* vtk_input;
    vtkPolyData* vtk_output;
    vtkPolyData* vtk_medial_surface;
    
    // some hacks to enable us to have useful error reporting
    vtkPowerCrustSurfaceReconstruction *our_filter;
    
};

//=====================================================================

vtkPowerCrustSurfaceReconstructionImpl::vtkPowerCrustSurfaceReconstructionImpl ( void )
{
}

long vtkPowerCrustSurfaceReconstructionImpl::site_numm ( site p )
{
    if ( ( vd_new || power_diagram ) && p==infinity ) return -1;
    if ( !p ) return -2;
    for ( int i = 0; i<num_blocks; i++ )
    {
        long j;
        if ( ( j = p-site_blocks[i] ) >= 0 && j < BLOCKSIZE * dim )
            return j / dim + BLOCKSIZE * i;
    }
    return -3;
}

site vtkPowerCrustSurfaceReconstructionImpl::new_site ( site p, long j )
{
    assert ( num_blocks + 1 < MAXBLOCKS );
    if ( 0 == ( j % BLOCKSIZE ) )
    {
        num_blocks++;
        site_blocks.resize ( num_blocks );
        site_blocks[num_blocks - 1] = ( site ) malloc ( BLOCKSIZE * site_size );
        site_blocks_pointers.push_back ( site_blocks[num_blocks - 1] );
        return site_blocks[num_blocks - 1];
    }
    else
        return p + dim;
}

void vtkPowerCrustSurfaceReconstructionImpl::read_bounding_box ( long j )
{
    int i,k;
    double center[3],width;
    
    omaxs[0] = maxs[0];
    omins[0] = mins[0];
    omaxs[1] = maxs[1];
    omins[1] = mins[1];
    omaxs[2] = maxs[2];
    omins[2] = mins[2];
    
    center[0] = ( maxs[0] - mins[0] ) /2;
    center[1] = ( maxs[1] - mins[1] ) /2;
    center[2] = ( maxs[2] - mins[2] ) /2;
    if ( ( maxs[0] - mins[0] ) > ( maxs[1] - mins[1] ) )
    {
        if ( ( maxs[2] - mins[2] ) > ( maxs[0] - mins[0] ) )
            width = maxs[2] - mins[2];
        else width = maxs[0] - mins[0];
    }
    else
    {
        if ( ( maxs[1] - mins[1] ) > ( maxs[2] - mins[2] ) )
            width = maxs[1] - mins[1];
        else width = maxs[2] - mins[2];
    }
    
    width = width * 4;
    
    bound[0][0] = center[0] + width;
    bound[1][0] = bound[0][0];
    bound[2][0] = bound[0][0];
    bound[3][0] = bound[0][0];
    bound[0][1] = center[1] + width;
    bound[1][1] = bound[0][1];
    bound[4][1] = bound[0][1];
    bound[5][1] = bound[0][1];
    bound[0][2] = center[2] + width;
    bound[2][2] = bound[0][2];
    bound[4][2] = bound[0][2];
    bound[6][2] = bound[0][2];
    bound[4][0] = center[0] - width;
    bound[5][0] = bound[4][0];
    bound[6][0] = bound[4][0];
    bound[7][0] = bound[4][0];
    bound[2][1] = center[1] - width;
    bound[3][1] = bound[2][1];
    bound[6][1] = bound[2][1];
    bound[7][1] = bound[2][1];
    bound[1][2] = center[2] - width;
    bound[3][2] = bound[1][2];
    bound[5][2] = bound[1][2];
    bound[7][2] = bound[1][2];
    
    for ( k = 0; k < 3; k++ )
    {
        p[k] = bound[0][k];
    }
    
    for ( i = 1; i < 8; i++ )
    {
        p = new_site ( p, j+i );
        for ( k=0; k<3; k++ )
        {
            p[k] = bound[i][k];
        }
    }
    maxs[0] = bound[0][0];
    mins[0] = bound[4][0];
    maxs[1] = bound[0][1];
    mins[1] = bound[2][1];
    maxs[2] = bound[0][2];
    mins[2] = bound[1][2];
}

site vtkPowerCrustSurfaceReconstructionImpl::vtk_read_next_site ( long j )
{
    ASSERT ( j >= 0, "vtk_read_next_site " );
    p = new_site ( p, j );
    
    for ( int i=0; i<dim; i++ )
    {
        p[i] = ( double ) vtk_input->GetPoint ( j ) [i];
        p[i] = floor ( mult_up*p[i]+0.5 );
        mins[i] = ( mins[i]<p[i] ) ? mins[i] : p[i];
        maxs[i] = ( maxs[i]>p[i] ) ? maxs[i] : p[i];
    }
    
    return p;
}

site vtkPowerCrustSurfaceReconstructionImpl::vtk_pole_read_next_site ( long j )
{
    ASSERT ( j >= 0, "vtk_pole_read_next_site" );
    p = new_site ( p, j );
    
    for ( int i = 0; i < dim; i++ )
    {
        if ( i < 3 )
            p[i] = ( double ) vtk_medial_surface->GetPoint ( j ) [i];
        else
            p[i] = ( double ) vtk_medial_surface->GetPointData()->GetScalars()->GetTuple1 ( j );
        p[i] = floor ( mult_up*p[i]+0.5 );
        mins[i] = ( mins[i]<p[i] ) ? mins[i] : p[i];
        maxs[i] = ( maxs[i]>p[i] ) ? maxs[i] : p[i];
    }
    
    return p;
}

site vtkPowerCrustSurfaceReconstructionImpl::get_site_offline ( long i )
{
    if ( i >= num_sites ) return NULL;
    else
    {
        return site_blocks[i / BLOCKSIZE]+ ( i % BLOCKSIZE ) * dim;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::make_shuffle ( void )
{
    if ( mat_size<=num_sites )
    {
        mat_size = num_sites+1;
        shufmat.resize ( mat_size );
    }
    for ( long i = 0; i <= num_sites; i++ )
    {
        shufmat[i] = i;
    }
    for ( long i = 0; i < num_sites; i++ )
    {
        long t = shufmat[i];
        long j = i + ( long ) ( ( num_sites-i ) *double_rand() ); // cast to long added by TJH
        shufmat[i] = shufmat[j];
        shufmat[j] = t;
    }
}

long vtkPowerCrustSurfaceReconstructionImpl::shufflef ( long i )
{
    return shufmat[i];
}

site vtkPowerCrustSurfaceReconstructionImpl::get_next_site ( void )
{
    return ( this->*get_site_n ) ( ( this->*shuf ) ( s_num++ ) );
}

void vtkPowerCrustSurfaceReconstructionImpl::make_output ( simplex *root, void * ( vtkPowerCrustSurfaceReconstructionImpl::*visit_gen ) ( simplex*, visit_func ), visit_func visit )
{
    //   ( this->*visit ) ( 0, ( void ( * ) ) out_funcp );
    ( this->*visit_gen ) ( root, visit );
}

void vtkPowerCrustSurfaceReconstructionImpl::ASSERT ( int b, const char* message )
{
    if ( !b )
    {
        our_filter->Error ( message );
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::freeAll ( void )
{
    for ( unsigned int i = 0; i < adjlist.size(); i++ )
    {
        edgesimp *tmpEdgesimp;
        edgesimp *curEdgesimp;
        curEdgesimp = adjlist[i].eptr;
        while ( curEdgesimp )
        {
            tmpEdgesimp = curEdgesimp;
            curEdgesimp = tmpEdgesimp->next;
            free ( tmpEdgesimp );
        }
    }
    
    for ( unsigned int i = 0; i < opplist.size(); i++ )
    {
        if ( opplist[i] != NULL )
        {
            plist *tmpPlist;
            plist *curPlist;
            curPlist = opplist[i];
            while ( curPlist )
            {
                tmpPlist = curPlist;
                curPlist = tmpPlist->next;
                free ( tmpPlist );
            }
        }
    }
    free ( pole1_distance );
    free ( pole2_distance );
    
    free ( pole1 );
    free ( pole2 );
    
    free ( lfs_lb );
    
    free_hull_storage();
    
    free ( p_neigh.basis );
    free ( seesB );
    free ( st_search );
    free ( st_visit_triang_gen );
    
    for ( unsigned int i = 0; i < site_blocks_pointers.size(); i++ )
        free ( site_blocks_pointers[i] );
    
    free_heap();  // EPRO added
}

void vtkPowerCrustSurfaceReconstructionImpl::adapted_main ( double m_mult_up )
{
    int num_poles = 0;
    
    simplex *root;
    
    edgesimp *eindex;
    visit_func pr;
    mult_up = m_mult_up;
    est_r = our_filter->GetEstimateR();
    
    short bad = 0;
    long poleid = 0;
    double samp[3];
    dim = 3;
    
    if ( dim > MAXDIM ) ASSERT ( pcFALSE, "dimension bound MAXDIM exceeded" );
    
    site_size = sizeof ( Coord ) *dim;
    
    // TJH: we've replaced this file-reading loop with the loop below
    for ( num_sites = 0; num_sites<vtk_input->GetNumberOfPoints(); num_sites++ )
    {
        vtk_read_next_site ( num_sites );
    }
    num_sites--;
    
    read_bounding_box ( num_sites );
    num_sites += 8;
    init_rand();
    make_shuffle();
    shuf = &vtkPowerCrustSurfaceReconstructionImpl::shufflef;
    get_site_n = &vtkPowerCrustSurfaceReconstructionImpl::get_site_offline;
    
    /* Step 1: compute DT of input point set */
    root = build_convex_hull ( dim, vd_new );
    
    /* Step 2: Find poles */
    pole1 = ( simplex ** ) calloc ( num_sites, sizeof ( simplex * ) );
    pole2 = ( simplex ** ) calloc ( num_sites, sizeof ( simplex * ) );
    lfs_lb = ( double* ) calloc ( num_sites, sizeof ( double ) );
    
    exactinit(); /* Shewchuk's exact arithmetic initialization */
    
    pr = &vtkPowerCrustSurfaceReconstructionImpl::compute_vv;
    make_output ( root, &vtkPowerCrustSurfaceReconstructionImpl::visit_hull, pr );
    
    pr = &vtkPowerCrustSurfaceReconstructionImpl::compute_pole2;
    make_output ( root, &vtkPowerCrustSurfaceReconstructionImpl::visit_hull, pr );
    
    /* initialize the sample distance info for the poles */
    
    pole1_distance = ( double * ) malloc ( num_sites*sizeof ( double ) );
    pole2_distance = ( double * ) malloc ( num_sites*sizeof ( double ) );
    
    compute_distance ( pole1,num_sites-8,pole1_distance );
    compute_distance ( pole2,num_sites-8,pole2_distance );
    
    /* intialize list of lists of pointers to opposite poles */
    opplist.resize ( 2 * num_sites );
    
    /* data about poles; adjacencies, labels, radii */
    adjlist.resize ( 2 * num_sites );
    
    /* loop through sites, writing out poles */
    for ( int i = 0; i < num_sites - 8; i++ )
    {
        /* rescale the sample to real input coordinates */
        for ( int k = 0; k < 3; k++ )
            samp[k] = get_site_offline ( i ) [k]/mult_up;
        
        /* output poles, both to debugging file and for weighted DT */
        /* remembers sqaured radius */
        if ( ( pole1[i]!=NULL ) && ( pole1[i]->status != POLE_OUTPUT ) )
        {
            /* if second pole is closer than we think it should be... */
            if ( ( pole2[i]!=NULL ) && bad && close_pole ( samp,pole2[i]->vv, lfs_lb[i] ) )
            {
            }
            else
            {
                outputPole ( pole1[i],poleid++,samp,&num_poles,pole1_distance[i] );
            }
        }
        
        if ( ( pole2[i]!=NULL ) && ( pole2[i]->status != POLE_OUTPUT ) )
        {
            /* if pole is closer than we think it should be... */
            if ( close_pole ( samp,pole2[i]->vv,lfs_lb[i] ) )
            {
                /* remember opposite bad for late labeling */
                if ( !bad ) adjlist[pole1[i]->poleindex].bad = BAD_POLE;
                continue;
            }
            
            outputPole ( pole2[i],poleid++,samp,&num_poles,pole2_distance[i] );
        }
        
        /* keep list of opposite poles for later coloring */
        if ( ( pole1[i] != NULL ) && ( pole2[i] != NULL ) && ( pole1[i]->status == POLE_OUTPUT ) && ( pole2[i]->status == POLE_OUTPUT ) )
        {
            double pole_angle = computePoleAngle ( pole1[i],pole2[i],samp );
            
            newOpposite ( pole1[i]->poleindex, pole2[i]->poleindex, pole_angle );
            newOpposite ( pole2[i]->poleindex, pole1[i]->poleindex, pole_angle );
        }
    }
    
    free_hull_storage();
    
    power_diagram = 1;
    vd_new = 0;
    dim = 4;
    
    // TJH: uncommented this line, seemed like we need to free this memory before num_blocks gets reset
    for ( unsigned int i = 0; i < site_blocks_pointers.size(); i++ )
    {
        free ( site_blocks_pointers[i] );
    }
    site_blocks_pointers.clear();
    
    num_blocks = 0;
    s_num = 0;
    scount = 0;
    
    site_size = sizeof ( Coord ) *dim;
    /* save points in order read */
    for ( num_sites=0; num_sites<vtk_medial_surface->GetNumberOfPoints(); num_sites++ )
    {
        vtk_pole_read_next_site ( num_sites );
    }
    //num_sites--;
    
    /* set up the shuffle */
    init_rand();
    make_shuffle();
    shuf = &vtkPowerCrustSurfaceReconstructionImpl::shufflef;
    get_site_n = &vtkPowerCrustSurfaceReconstructionImpl::get_site_offline;  /* returns stored points, unshuffled */
    
    /* Compute weighted DT  */
    root = build_convex_hull ( dim, vd_new );
    
    /* compute adjacencies and find angles of ball intersections */
    pr = &vtkPowerCrustSurfaceReconstructionImpl::compute_3d_power_vv;
    make_output ( root, &vtkPowerCrustSurfaceReconstructionImpl::visit_hull, pr );
    
    /* labeling */
    init_heap ( num_poles );
    for ( int i = 0; i < num_poles; i++ )
    {
        if ( ( get_site_offline ( i ) [0]> ( 2*omaxs[0]-omins[0] ) ) ||
            ( get_site_offline ( i ) [0]< ( 2*omins[0]-omaxs[0] ) ) ||
            ( get_site_offline ( i ) [1]> ( 2*omaxs[1]-omins[1] ) ) ||
            ( get_site_offline ( i ) [1]< ( 2*omins[1]-omaxs[1] ) ) ||
            ( get_site_offline ( i ) [2]> ( 2*omaxs[2]-omins[2] ) ) ||
            ( get_site_offline ( i ) [2]< ( 2*omins[2]-omaxs[2] ) ) )
        {
            adjlist[i].hid = insert_heap ( i,1.0 );
            adjlist[i].out = 1.0;
            adjlist[i].label = OUT;
        }
    }
    
    while ( heap_size != 0 )
        propagate();
    
    label_unlabeled ( num_poles );
    
    for ( int i = 0; i < num_poles; i++ )
    {
        if ( ( adjlist[i].label != IN ) && ( adjlist[i].label != OUT ) )
        {
        }
        else
        {
            eindex = adjlist[i].eptr;
            while ( eindex!=NULL )
            {
                if ( ( i < eindex->pid ) && ( antiLabel ( adjlist[i].label ) == adjlist[eindex->pid].label ) )
                {
                    construct_face ( eindex->simp,eindex->kth );
                }
                eindex = eindex->next;
            }
        }
    }
    
    /* compute the medial axis */
    pr = &vtkPowerCrustSurfaceReconstructionImpl::compute_axis;
    make_output ( root, &vtkPowerCrustSurfaceReconstructionImpl::visit_hull, pr );
}

void vtkPowerCrustSurfaceReconstructionImpl::compute_distance ( simplex** poles, int size, double* distance )
{
    double indices[4][3]; /* the coords of the four vertices of the simplex*/
    point v[MAXDIM];
    simplex* currSimplex;
    double maxdistance = 0;
    
    for ( int l = 0; l < size; l++ ) /* for each pole do*/
    {
        if ( poles[l] != NULL )
        {
            currSimplex = poles[l];
            
            /* get the coordinates of the  four endpoints */
            for ( int j = 0; j < 4; j++ )
            {
                v[j] = currSimplex->neigh[j].vert;
                
                for ( int k = 0; k < 3; k++ )
                    indices[j][k] = v[j][k] / mult_up;
            }
            
            /* now compute the actual distance  */
            maxdistance = 0;
            
            for ( int i = 0; i < 4; i++ )
            {
                for ( int j = i + 1; j < 4; j++ )
                {
                    double currdistance = SQ ( indices[i][0]-indices[j][0] ) + SQ ( indices[i][1]-indices[j][1] ) + SQ ( indices[i][2]-indices[j][2] );
                    currdistance = sqrt ( currdistance );
                    if ( maxdistance < currdistance )
                        maxdistance = currdistance;
                }
            }
            
            distance[l] = maxdistance;
        }
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::pcInit ()
{
    pcFALSE = ( 1 == 0 );
    pcTRUE = ( 1 == 1 );
    
    vtk_input = NULL;
    vtk_output = NULL;
    vtk_medial_surface = NULL;
    our_filter = NULL;
    seesB = NULL;
    check_perps_b = NULL;
    p = NULL;
    pole1_distance = NULL;
    pole2_distance = NULL;
    st_search = NULL;
    st_visit_triang_gen = NULL;
    ch_root = NULL;
    pole1 = NULL;
    pole2 = NULL;
    lfs_lb = NULL;
    site_num = NULL;
    heap_A = NULL;
    make_facets_ns = NULL;
    
    site_blocks.clear();
    site_blocks_pointers.clear();
    adjlist.clear();
    opplist.clear();
    
    num_blocks = 0;
    mult_up = 1.0;
    num_vtxs = 0;
    est_r = 0.6;
    num_poles = 0;
    heap_size = 0;
    scount = 0;
    vd_new = 1;
    power_diagram = 0;
    s_num = 0;
    theta = 0.0;
    deep = 0.0;
    mat_size = 0;
    loopStart = -1;
    count = 0;
    lastCount = 0;
    visit_triang_gen_vnum = -1;
    visit_triang_gen_ss = 2000;
    pdim = 0;
    rdim = 0;
    cdim = 0;
    site_size = 0;
    pnum = 0;
    num_sites = 0;
    dim = 0;
    basis_vec_size = 0;
    exact_bits = 0;
    b_err_min = 0;
    b_err_min_sq = 0;
    sc_lscale = 0;
    sc_max_scale = 0;
    sc_ldetbound = 0;
    sc_Sb = 0;
    alpha_test_alpha = 0;
    heap_length = 0;
    search_ss = MAXDIM;
    Huge = DBL_MAX;
    vd = 0;
    _rand48_add = RAND48_ADD;
    
    infinity[0] = 57.2;
    infinity[1] = 0;
    infinity[2] = 0;
    infinity[3] = 0;
    infinity[4] = 0;
    
    v1[0] = 0;
    v1[1] = 0;
    v1[2] = 0;
    v1[3] = 1;
    v1[4] = 1;
    v1[5] = 2;
    
    v2[0] = 1;
    v2[1] = 2;
    v2[2] = 3;
    v2[3] = 2;
    v2[4] = 3;
    v2[5] = 3;
    
    v3[0] = 2;
    v3[1] = 3;
    v3[2] = 1;
    v3[3] = 3;
    v3[4] = 0;
    v3[5] = 0;
    
    v4[0] = 3;
    v4[1] = 1;
    v4[2] = 2;
    v4[3] = 0;
    v4[4] = 2;
    v4[5] = 1;
    
    for ( int i = 0; i < 8; i++ )
    {
        for ( int j = 0; j < 3; j++ )
        {
            bound[i][j] = 0;
        }
    }
    for ( int i = 0; i < MAXPOINTS; i++ )
    {
        mi[i] = 0;
        mo[i] = 0;
    }
    
    omins[0] = 0;
    omins[1] = 0;
    omins[2] = 0;
    omaxs[0] = 0;
    omaxs[1] = 0;
    omaxs[2] = 0;
    
    p_neigh.vert = 0;
    p_neigh.basis = 0;
    p_neigh.simp = 0;
    
    X [0] = 0;
    X [1] = 10000;
    X [2] = 0;
    
    for ( int i = 0; i < MAXDIM; i++ )
    {
        mins[i] = DBL_MAX;
        maxs[i] = -DBL_MAX;
    }
    
    tt_basis.next = 0;
    tt_basis.ref_count = 1;
    tt_basis.lscale = -1;
    tt_basis.sqa = 0;
    tt_basis.sqb = 0;
    tt_basis.vecs[0] = 0;
    tt_basisp = &tt_basis;
    infinity_basis = NULL;
    
    X[0] = 0;
    X[1] = 0;
    X[2] = 0;
    
    _rand48_mult[0] = RAND48_MULT_0;
    _rand48_mult[1] = RAND48_MULT_1;
    _rand48_mult[2] = RAND48_MULT_2;
    _rand48_add = RAND48_ADD;
}

void vtkPowerCrustSurfaceReconstructionImpl::_dorand48 ( unsigned short xseed[3] )
{
    unsigned long accu;
    unsigned short temp[2];
    
    accu = ( unsigned long ) _rand48_mult[0] * ( unsigned long ) xseed[0] + ( unsigned long ) _rand48_add;
    temp[0] = ( unsigned short ) accu; /* lower 16 bits */
    accu >>= sizeof ( unsigned short ) * 8;
    accu += ( unsigned long ) _rand48_mult[0] * ( unsigned long ) xseed[1] + ( unsigned long ) _rand48_mult[1] * ( unsigned long ) xseed[0];
    temp[1] = ( unsigned short ) accu; /* middle 16 bits */
    accu >>= sizeof ( unsigned short ) * 8;
    accu += _rand48_mult[0] * xseed[2] + _rand48_mult[1] * xseed[1] + _rand48_mult[2] * xseed[0];
    xseed[0] = temp[0];
    xseed[1] = temp[1];
    xseed[2] = ( unsigned short ) accu;
}

double vtkPowerCrustSurfaceReconstructionImpl::local_erand48 ( unsigned short xseed[3] ) throw()
{
    _dorand48 ( xseed );
    return ldexp ( ( double ) xseed[0], -48 ) + ldexp ( ( double ) xseed[1], -32 ) + ldexp ( ( double ) xseed[2], -16 );
}

double vtkPowerCrustSurfaceReconstructionImpl::double_rand ( void )
{
    return local_erand48 ( X );
}

void vtkPowerCrustSurfaceReconstructionImpl::init_rand ( void )
{
    X[1] = 10000;
}

double vtkPowerCrustSurfaceReconstructionImpl::logb ( double x )
{
    return log ( x ) /log ( 2.0 ); // EPRO added
}

REAL vtkPowerCrustSurfaceReconstructionImpl::orient3dadapt ( REAL *pa,REAL *pb,REAL *pc,REAL *pd,REAL permanent )
{
    INEXACT REAL adx, bdx, cdx, ady, bdy, cdy, adz, bdz, cdz;
    REAL det, errbound;
    
    INEXACT REAL bdxcdy1, cdxbdy1, cdxady1, adxcdy1, adxbdy1, bdxady1;
    REAL bdxcdy0, cdxbdy0, cdxady0, adxcdy0, adxbdy0, bdxady0;
    REAL bc[4], ca[4], ab[4];
    INEXACT REAL bc3, ca3, ab3;
    REAL adet[8], bdet[8], cdet[8];
    int alen, blen, clen;
    REAL abdet[16];
    int ablen;
    REAL *finnow, *finother, *finswap;
    REAL fin1[192], fin2[192];
    int finlength;
    
    REAL adxtail, bdxtail, cdxtail;
    REAL adytail, bdytail, cdytail;
    REAL adztail, bdztail, cdztail;
    INEXACT REAL at_blarge, at_clarge;
    INEXACT REAL bt_clarge, bt_alarge;
    INEXACT REAL ct_alarge, ct_blarge;
    REAL at_b[4], at_c[4], bt_c[4], bt_a[4], ct_a[4], ct_b[4];
    int at_blen, at_clen, bt_clen, bt_alen, ct_alen, ct_blen;
    INEXACT REAL bdxt_cdy1, cdxt_bdy1, cdxt_ady1;
    INEXACT REAL adxt_cdy1, adxt_bdy1, bdxt_ady1;
    REAL bdxt_cdy0, cdxt_bdy0, cdxt_ady0;
    REAL adxt_cdy0, adxt_bdy0, bdxt_ady0;
    INEXACT REAL bdyt_cdx1, cdyt_bdx1, cdyt_adx1;
    INEXACT REAL adyt_cdx1, adyt_bdx1, bdyt_adx1;
    REAL bdyt_cdx0, cdyt_bdx0, cdyt_adx0;
    REAL adyt_cdx0, adyt_bdx0, bdyt_adx0;
    REAL bct[8], cat[8], abt[8];
    int bctlen, catlen, abtlen;
    INEXACT REAL bdxt_cdyt1, cdxt_bdyt1, cdxt_adyt1;
    INEXACT REAL adxt_cdyt1, adxt_bdyt1, bdxt_adyt1;
    REAL bdxt_cdyt0, cdxt_bdyt0, cdxt_adyt0;
    REAL adxt_cdyt0, adxt_bdyt0, bdxt_adyt0;
    REAL u[4], v[12], w[16];
    INEXACT REAL u3;
    int vlength, wlength;
    REAL negate;
    
    INEXACT REAL bvirt;
    REAL avirt, bround, around;
    INEXACT REAL c;
    INEXACT REAL abig;
    REAL ahi, alo, bhi, blo;
    REAL err1, err2, err3;
    INEXACT REAL _i, _j, _k;
    REAL _0;
    
    adx = ( REAL ) ( pa[0] - pd[0] );
    bdx = ( REAL ) ( pb[0] - pd[0] );
    cdx = ( REAL ) ( pc[0] - pd[0] );
    ady = ( REAL ) ( pa[1] - pd[1] );
    bdy = ( REAL ) ( pb[1] - pd[1] );
    cdy = ( REAL ) ( pc[1] - pd[1] );
    adz = ( REAL ) ( pa[2] - pd[2] );
    bdz = ( REAL ) ( pb[2] - pd[2] );
    cdz = ( REAL ) ( pc[2] - pd[2] );
    
    Two_Product ( bdx, cdy, bdxcdy1, bdxcdy0 );
    Two_Product ( cdx, bdy, cdxbdy1, cdxbdy0 );
    Two_Two_Diff ( bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0, bc3, bc[2], bc[1], bc[0] );
    bc[3] = bc3;
    alen = scale_expansion_zeroelim ( 4, bc, adz, adet );
    
    Two_Product ( cdx, ady, cdxady1, cdxady0 );
    Two_Product ( adx, cdy, adxcdy1, adxcdy0 );
    Two_Two_Diff ( cdxady1, cdxady0, adxcdy1, adxcdy0, ca3, ca[2], ca[1], ca[0] );
    ca[3] = ca3;
    blen = scale_expansion_zeroelim ( 4, ca, bdz, bdet );
    
    Two_Product ( adx, bdy, adxbdy1, adxbdy0 );
    Two_Product ( bdx, ady, bdxady1, bdxady0 );
    Two_Two_Diff ( adxbdy1, adxbdy0, bdxady1, bdxady0, ab3, ab[2], ab[1], ab[0] );
    ab[3] = ab3;
    clen = scale_expansion_zeroelim ( 4, ab, cdz, cdet );
    
    ablen = fast_expansion_sum_zeroelim ( alen, adet, blen, bdet, abdet );
    finlength = fast_expansion_sum_zeroelim ( ablen, abdet, clen, cdet, fin1 );
    
    det = estimate ( finlength, fin1 );
    errbound = o3derrboundB * permanent;
    if ( ( det >= errbound ) || ( -det >= errbound ) )
    {
        return det;
    }
    
    Two_Diff_Tail ( pa[0], pd[0], adx, adxtail );
    Two_Diff_Tail ( pb[0], pd[0], bdx, bdxtail );
    Two_Diff_Tail ( pc[0], pd[0], cdx, cdxtail );
    Two_Diff_Tail ( pa[1], pd[1], ady, adytail );
    Two_Diff_Tail ( pb[1], pd[1], bdy, bdytail );
    Two_Diff_Tail ( pc[1], pd[1], cdy, cdytail );
    Two_Diff_Tail ( pa[2], pd[2], adz, adztail );
    Two_Diff_Tail ( pb[2], pd[2], bdz, bdztail );
    Two_Diff_Tail ( pc[2], pd[2], cdz, cdztail );
    
    if ( ( adxtail == 0.0 ) && ( bdxtail == 0.0 ) && ( cdxtail == 0.0 )
        && ( adytail == 0.0 ) && ( bdytail == 0.0 ) && ( cdytail == 0.0 )
        && ( adztail == 0.0 ) && ( bdztail == 0.0 ) && ( cdztail == 0.0 ) )
    {
        return det;
    }
    
    errbound = o3derrboundC * permanent + resulterrbound * Absolute ( det );
    det += ( adz * ( ( bdx * cdytail + cdy * bdxtail )
                    - ( bdy * cdxtail + cdx * bdytail ) )
            + adztail * ( bdx * cdy - bdy * cdx ) )
    + ( bdz * ( ( cdx * adytail + ady * cdxtail )
               - ( cdy * adxtail + adx * cdytail ) )
       + bdztail * ( cdx * ady - cdy * adx ) )
    + ( cdz * ( ( adx * bdytail + bdy * adxtail )
               - ( ady * bdxtail + bdx * adytail ) )
       + cdztail * ( adx * bdy - ady * bdx ) );
    if ( ( det >= errbound ) || ( -det >= errbound ) )
    {
        return det;
    }
    
    finnow = fin1;
    finother = fin2;
    
    if ( adxtail == 0.0 )
    {
        if ( adytail == 0.0 )
        {
            at_b[0] = 0.0;
            at_blen = 1;
            at_c[0] = 0.0;
            at_clen = 1;
        }
        else
        {
            negate = -adytail;
            Two_Product ( negate, bdx, at_blarge, at_b[0] );
            at_b[1] = at_blarge;
            at_blen = 2;
            Two_Product ( adytail, cdx, at_clarge, at_c[0] );
            at_c[1] = at_clarge;
            at_clen = 2;
        }
    }
    else
    {
        if ( adytail == 0.0 )
        {
            Two_Product ( adxtail, bdy, at_blarge, at_b[0] );
            at_b[1] = at_blarge;
            at_blen = 2;
            negate = -adxtail;
            Two_Product ( negate, cdy, at_clarge, at_c[0] );
            at_c[1] = at_clarge;
            at_clen = 2;
        }
        else
        {
            Two_Product ( adxtail, bdy, adxt_bdy1, adxt_bdy0 );
            Two_Product ( adytail, bdx, adyt_bdx1, adyt_bdx0 );
            Two_Two_Diff ( adxt_bdy1, adxt_bdy0, adyt_bdx1, adyt_bdx0,
                          at_blarge, at_b[2], at_b[1], at_b[0] );
            at_b[3] = at_blarge;
            at_blen = 4;
            Two_Product ( adytail, cdx, adyt_cdx1, adyt_cdx0 );
            Two_Product ( adxtail, cdy, adxt_cdy1, adxt_cdy0 );
            Two_Two_Diff ( adyt_cdx1, adyt_cdx0, adxt_cdy1, adxt_cdy0,
                          at_clarge, at_c[2], at_c[1], at_c[0] );
            at_c[3] = at_clarge;
            at_clen = 4;
        }
    }
    if ( bdxtail == 0.0 )
    {
        if ( bdytail == 0.0 )
        {
            bt_c[0] = 0.0;
            bt_clen = 1;
            bt_a[0] = 0.0;
            bt_alen = 1;
        }
        else
        {
            negate = -bdytail;
            Two_Product ( negate, cdx, bt_clarge, bt_c[0] );
            bt_c[1] = bt_clarge;
            bt_clen = 2;
            Two_Product ( bdytail, adx, bt_alarge, bt_a[0] );
            bt_a[1] = bt_alarge;
            bt_alen = 2;
        }
    }
    else
    {
        if ( bdytail == 0.0 )
        {
            Two_Product ( bdxtail, cdy, bt_clarge, bt_c[0] );
            bt_c[1] = bt_clarge;
            bt_clen = 2;
            negate = -bdxtail;
            Two_Product ( negate, ady, bt_alarge, bt_a[0] );
            bt_a[1] = bt_alarge;
            bt_alen = 2;
        }
        else
        {
            Two_Product ( bdxtail, cdy, bdxt_cdy1, bdxt_cdy0 );
            Two_Product ( bdytail, cdx, bdyt_cdx1, bdyt_cdx0 );
            Two_Two_Diff ( bdxt_cdy1, bdxt_cdy0, bdyt_cdx1, bdyt_cdx0,
                          bt_clarge, bt_c[2], bt_c[1], bt_c[0] );
            bt_c[3] = bt_clarge;
            bt_clen = 4;
            Two_Product ( bdytail, adx, bdyt_adx1, bdyt_adx0 );
            Two_Product ( bdxtail, ady, bdxt_ady1, bdxt_ady0 );
            Two_Two_Diff ( bdyt_adx1, bdyt_adx0, bdxt_ady1, bdxt_ady0,
                          bt_alarge, bt_a[2], bt_a[1], bt_a[0] );
            bt_a[3] = bt_alarge;
            bt_alen = 4;
        }
    }
    if ( cdxtail == 0.0 )
    {
        if ( cdytail == 0.0 )
        {
            ct_a[0] = 0.0;
            ct_alen = 1;
            ct_b[0] = 0.0;
            ct_blen = 1;
        }
        else
        {
            negate = -cdytail;
            Two_Product ( negate, adx, ct_alarge, ct_a[0] );
            ct_a[1] = ct_alarge;
            ct_alen = 2;
            Two_Product ( cdytail, bdx, ct_blarge, ct_b[0] );
            ct_b[1] = ct_blarge;
            ct_blen = 2;
        }
    }
    else
    {
        if ( cdytail == 0.0 )
        {
            Two_Product ( cdxtail, ady, ct_alarge, ct_a[0] );
            ct_a[1] = ct_alarge;
            ct_alen = 2;
            negate = -cdxtail;
            Two_Product ( negate, bdy, ct_blarge, ct_b[0] );
            ct_b[1] = ct_blarge;
            ct_blen = 2;
        }
        else
        {
            Two_Product ( cdxtail, ady, cdxt_ady1, cdxt_ady0 );
            Two_Product ( cdytail, adx, cdyt_adx1, cdyt_adx0 );
            Two_Two_Diff ( cdxt_ady1, cdxt_ady0, cdyt_adx1, cdyt_adx0,
                          ct_alarge, ct_a[2], ct_a[1], ct_a[0] );
            ct_a[3] = ct_alarge;
            ct_alen = 4;
            Two_Product ( cdytail, bdx, cdyt_bdx1, cdyt_bdx0 );
            Two_Product ( cdxtail, bdy, cdxt_bdy1, cdxt_bdy0 );
            Two_Two_Diff ( cdyt_bdx1, cdyt_bdx0, cdxt_bdy1, cdxt_bdy0,
                          ct_blarge, ct_b[2], ct_b[1], ct_b[0] );
            ct_b[3] = ct_blarge;
            ct_blen = 4;
        }
    }
    
    bctlen = fast_expansion_sum_zeroelim ( bt_clen, bt_c, ct_blen, ct_b, bct );
    wlength = scale_expansion_zeroelim ( bctlen, bct, adz, w );
    finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                             finother );
    finswap = finnow;
    finnow = finother;
    finother = finswap;
    
    catlen = fast_expansion_sum_zeroelim ( ct_alen, ct_a, at_clen, at_c, cat );
    wlength = scale_expansion_zeroelim ( catlen, cat, bdz, w );
    finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                             finother );
    finswap = finnow;
    finnow = finother;
    finother = finswap;
    
    abtlen = fast_expansion_sum_zeroelim ( at_blen, at_b, bt_alen, bt_a, abt );
    wlength = scale_expansion_zeroelim ( abtlen, abt, cdz, w );
    finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                             finother );
    finswap = finnow;
    finnow = finother;
    finother = finswap;
    
    if ( adztail != 0.0 )
    {
        vlength = scale_expansion_zeroelim ( 4, bc, adztail, v );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, vlength, v,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    if ( bdztail != 0.0 )
    {
        vlength = scale_expansion_zeroelim ( 4, ca, bdztail, v );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, vlength, v,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    if ( cdztail != 0.0 )
    {
        vlength = scale_expansion_zeroelim ( 4, ab, cdztail, v );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, vlength, v,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    
    if ( adxtail != 0.0 )
    {
        if ( bdytail != 0.0 )
        {
            Two_Product ( adxtail, bdytail, adxt_bdyt1, adxt_bdyt0 );
            Two_One_Product ( adxt_bdyt1, adxt_bdyt0, cdz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( cdztail != 0.0 )
            {
                Two_One_Product ( adxt_bdyt1, adxt_bdyt0, cdztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
        if ( cdytail != 0.0 )
        {
            negate = -adxtail;
            Two_Product ( negate, cdytail, adxt_cdyt1, adxt_cdyt0 );
            Two_One_Product ( adxt_cdyt1, adxt_cdyt0, bdz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( bdztail != 0.0 )
            {
                Two_One_Product ( adxt_cdyt1, adxt_cdyt0, bdztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
    }
    if ( bdxtail != 0.0 )
    {
        if ( cdytail != 0.0 )
        {
            Two_Product ( bdxtail, cdytail, bdxt_cdyt1, bdxt_cdyt0 );
            Two_One_Product ( bdxt_cdyt1, bdxt_cdyt0, adz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( adztail != 0.0 )
            {
                Two_One_Product ( bdxt_cdyt1, bdxt_cdyt0, adztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
        if ( adytail != 0.0 )
        {
            negate = -bdxtail;
            Two_Product ( negate, adytail, bdxt_adyt1, bdxt_adyt0 );
            Two_One_Product ( bdxt_adyt1, bdxt_adyt0, cdz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( cdztail != 0.0 )
            {
                Two_One_Product ( bdxt_adyt1, bdxt_adyt0, cdztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
    }
    if ( cdxtail != 0.0 )
    {
        if ( adytail != 0.0 )
        {
            Two_Product ( cdxtail, adytail, cdxt_adyt1, cdxt_adyt0 );
            Two_One_Product ( cdxt_adyt1, cdxt_adyt0, bdz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( bdztail != 0.0 )
            {
                Two_One_Product ( cdxt_adyt1, cdxt_adyt0, bdztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
        if ( bdytail != 0.0 )
        {
            negate = -cdxtail;
            Two_Product ( negate, bdytail, cdxt_bdyt1, cdxt_bdyt0 );
            Two_One_Product ( cdxt_bdyt1, cdxt_bdyt0, adz, u3, u[2], u[1], u[0] );
            u[3] = u3;
            finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                     finother );
            finswap = finnow;
            finnow = finother;
            finother = finswap;
            if ( adztail != 0.0 )
            {
                Two_One_Product ( cdxt_bdyt1, cdxt_bdyt0, adztail, u3, u[2], u[1], u[0] );
                u[3] = u3;
                finlength = fast_expansion_sum_zeroelim ( finlength, finnow, 4, u,
                                                         finother );
                finswap = finnow;
                finnow = finother;
                finother = finswap;
            }
        }
    }
    
    if ( adztail != 0.0 )
    {
        wlength = scale_expansion_zeroelim ( bctlen, bct, adztail, w );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    if ( bdztail != 0.0 )
    {
        wlength = scale_expansion_zeroelim ( catlen, cat, bdztail, w );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    if ( cdztail != 0.0 )
    {
        wlength = scale_expansion_zeroelim ( abtlen, abt, cdztail, w );
        finlength = fast_expansion_sum_zeroelim ( finlength, finnow, wlength, w,
                                                 finother );
        finswap = finnow;
        finnow = finother;
        finother = finswap;
    }
    
    return finnow[finlength - 1];
}

REAL vtkPowerCrustSurfaceReconstructionImpl::orient3d ( REAL *pa,REAL *pb,REAL *pc,REAL *pd )
{
    REAL adx, bdx, cdx, ady, bdy, cdy, adz, bdz, cdz;
    REAL bdxcdy, cdxbdy, cdxady, adxcdy, adxbdy, bdxady;
    REAL det;
    REAL permanent, errbound;
    
    adx = pa[0] - pd[0];
    bdx = pb[0] - pd[0];
    cdx = pc[0] - pd[0];
    ady = pa[1] - pd[1];
    bdy = pb[1] - pd[1];
    cdy = pc[1] - pd[1];
    adz = pa[2] - pd[2];
    bdz = pb[2] - pd[2];
    cdz = pc[2] - pd[2];
    
    bdxcdy = bdx * cdy;
    cdxbdy = cdx * bdy;
    
    cdxady = cdx * ady;
    adxcdy = adx * cdy;
    
    adxbdy = adx * bdy;
    bdxady = bdx * ady;
    
    det = adz * ( bdxcdy - cdxbdy )
    + bdz * ( cdxady - adxcdy )
    + cdz * ( adxbdy - bdxady );
    
    permanent = ( Absolute ( bdxcdy ) + Absolute ( cdxbdy ) ) * Absolute ( adz )
    + ( Absolute ( cdxady ) + Absolute ( adxcdy ) ) * Absolute ( bdz )
    + ( Absolute ( adxbdy ) + Absolute ( bdxady ) ) * Absolute ( cdz );
    errbound = o3derrboundA * permanent;
    if ( ( det > errbound ) || ( -det > errbound ) )
    {
        return det;
    }
    
    return orient3dadapt ( pa, pb, pc, pd, permanent );
}

REAL vtkPowerCrustSurfaceReconstructionImpl::estimate ( int elen,REAL *e )
{
    REAL Q;
    int eindex;
    
    Q = e[0];
    for ( eindex = 1; eindex < elen; eindex++ )
    {
        Q += e[eindex];
    }
    return Q;
}

REAL vtkPowerCrustSurfaceReconstructionImpl::orient2dadapt ( REAL *pa,REAL *pb,REAL *pc,REAL detsum )
{
    INEXACT REAL acx, acy, bcx, bcy;
    REAL acxtail, acytail, bcxtail, bcytail;
    INEXACT REAL detleft, detright;
    REAL detlefttail, detrighttail;
    REAL det, errbound;
    REAL B[4], C1[8], C2[12], D[16];
    INEXACT REAL B3;
    int C1length, C2length, Dlength;
    REAL u[4];
    INEXACT REAL u3;
    INEXACT REAL s1, t1;
    REAL s0, t0;
    
    INEXACT REAL bvirt;
    REAL avirt, bround, around;
    INEXACT REAL c;
    INEXACT REAL abig;
    REAL ahi, alo, bhi, blo;
    REAL err1, err2, err3;
    INEXACT REAL _i, _j;
    REAL _0;
    
    acx = ( REAL ) ( pa[0] - pc[0] );
    bcx = ( REAL ) ( pb[0] - pc[0] );
    acy = ( REAL ) ( pa[1] - pc[1] );
    bcy = ( REAL ) ( pb[1] - pc[1] );
    
    Two_Product ( acx, bcy, detleft, detlefttail );
    Two_Product ( acy, bcx, detright, detrighttail );
    
    Two_Two_Diff ( detleft, detlefttail, detright, detrighttail,
                  B3, B[2], B[1], B[0] );
    B[3] = B3;
    
    det = estimate ( 4, B );
    errbound = ccwerrboundB * detsum;
    if ( ( det >= errbound ) || ( -det >= errbound ) )
    {
        return det;
    }
    
    Two_Diff_Tail ( pa[0], pc[0], acx, acxtail );
    Two_Diff_Tail ( pb[0], pc[0], bcx, bcxtail );
    Two_Diff_Tail ( pa[1], pc[1], acy, acytail );
    Two_Diff_Tail ( pb[1], pc[1], bcy, bcytail );
    
    if ( ( acxtail == 0.0 ) && ( acytail == 0.0 )
        && ( bcxtail == 0.0 ) && ( bcytail == 0.0 ) )
    {
        return det;
    }
    
    errbound = ccwerrboundC * detsum + resulterrbound * Absolute ( det );
    det += ( acx * bcytail + bcy * acxtail )
    - ( acy * bcxtail + bcx * acytail );
    if ( ( det >= errbound ) || ( -det >= errbound ) )
    {
        return det;
    }
    
    Two_Product ( acxtail, bcy, s1, s0 );
    Two_Product ( acytail, bcx, t1, t0 );
    Two_Two_Diff ( s1, s0, t1, t0, u3, u[2], u[1], u[0] );
    u[3] = u3;
    C1length = fast_expansion_sum_zeroelim ( 4, B, 4, u, C1 );
    
    Two_Product ( acx, bcytail, s1, s0 );
    Two_Product ( acy, bcxtail, t1, t0 );
    Two_Two_Diff ( s1, s0, t1, t0, u3, u[2], u[1], u[0] );
    u[3] = u3;
    C2length = fast_expansion_sum_zeroelim ( C1length, C1, 4, u, C2 );
    
    Two_Product ( acxtail, bcytail, s1, s0 );
    Two_Product ( acytail, bcxtail, t1, t0 );
    Two_Two_Diff ( s1, s0, t1, t0, u3, u[2], u[1], u[0] );
    u[3] = u3;
    Dlength = fast_expansion_sum_zeroelim ( C2length, C2, 4, u, D );
    
    return ( D[Dlength - 1] );
}

int vtkPowerCrustSurfaceReconstructionImpl::scale_expansion_zeroelim ( int elen, REAL *e, REAL b, REAL *h )
{
    INEXACT REAL Q, sum;
    REAL hh;
    INEXACT REAL product1;
    REAL product0;
    int eindex, hindex;
    REAL enow;
    INEXACT REAL bvirt;
    REAL avirt, bround, around;
    INEXACT REAL c;
    INEXACT REAL abig;
    REAL ahi, alo, bhi, blo;
    REAL err1, err2, err3;
    
    Split ( b, bhi, blo );
    Two_Product_Presplit ( e[0], b, bhi, blo, Q, hh );
    hindex = 0;
    if ( hh != 0 )
    {
        h[hindex++] = hh;
    }
    for ( eindex = 1; eindex < elen; eindex++ )
    {
        enow = e[eindex];
        Two_Product_Presplit ( enow, b, bhi, blo, product1, product0 );
        Two_Sum ( Q, product0, sum, hh );
        if ( hh != 0 )
        {
            h[hindex++] = hh;
        }
        Fast_Two_Sum ( product1, sum, Q, hh );
        if ( hh != 0 )
        {
            h[hindex++] = hh;
        }
    }
    if ( ( Q != 0.0 ) || ( hindex == 0 ) )
    {
        h[hindex++] = Q;
    }
    return hindex;
}

int vtkPowerCrustSurfaceReconstructionImpl::fast_expansion_sum_zeroelim ( int elen,REAL *e,int flen,REAL *f,REAL *h )
{
    REAL Q;
    INEXACT REAL Qnew;
    INEXACT REAL hh;
    INEXACT REAL bvirt;
    REAL avirt, bround, around;
    int eindex, findex, hindex;
    REAL enow, fnow;
    
    enow = e[0];
    fnow = f[0];
    eindex = findex = 0;
    if ( ( fnow > enow ) == ( fnow > -enow ) )
    {
        Q = enow;
        enow = e[++eindex];
    }
    else
    {
        Q = fnow;
        fnow = f[++findex];
    }
    hindex = 0;
    if ( ( eindex < elen ) && ( findex < flen ) )
    {
        if ( ( fnow > enow ) == ( fnow > -enow ) )
        {
            Fast_Two_Sum ( enow, Q, Qnew, hh );
            enow = e[++eindex];
        }
        else
        {
            Fast_Two_Sum ( fnow, Q, Qnew, hh );
            fnow = f[++findex];
        }
        Q = Qnew;
        if ( hh != 0.0 )
        {
            h[hindex++] = hh;
        }
        while ( ( eindex < elen ) && ( findex < flen ) )
        {
            if ( ( fnow > enow ) == ( fnow > -enow ) )
            {
                Two_Sum ( Q, enow, Qnew, hh );
                enow = e[++eindex];
            }
            else
            {
                Two_Sum ( Q, fnow, Qnew, hh );
                fnow = f[++findex];
            }
            Q = Qnew;
            if ( hh != 0.0 )
            {
                h[hindex++] = hh;
            }
        }
    }
    while ( eindex < elen )
    {
        Two_Sum ( Q, enow, Qnew, hh );
        enow = e[++eindex];
        Q = Qnew;
        if ( hh != 0.0 )
        {
            h[hindex++] = hh;
        }
    }
    while ( findex < flen )
    {
        Two_Sum ( Q, fnow, Qnew, hh );
        fnow = f[++findex];
        Q = Qnew;
        if ( hh != 0.0 )
        {
            h[hindex++] = hh;
        }
    }
    if ( ( Q != 0.0 ) || ( hindex == 0 ) )
    {
        h[hindex++] = Q;
    }
    return hindex;
}

void vtkPowerCrustSurfaceReconstructionImpl::exactinit()
{
    REAL half;
    REAL check, lastcheck;
    int every_other;
    
    every_other = 1;
    half = 0.5;
    epsilon = 1.0;
    splitter = 1.0;
    check = 1.0;
    /* Repeatedly divide `epsilon' by two until it is too small to add to    */
    /*   one without causing roundoff.  (Also check if the sum is equal to   */
    /*   the previous sum, for machines that round up instead of using exact */
    /*   rounding.  Not that this library will work on such machines anyway. */
    do
    {
        lastcheck = check;
        epsilon *= half;
        if ( every_other )
        {
            splitter *= 2.0;
        }
        every_other = !every_other;
        check = 1.0 + epsilon;
    }
    while ( ( check != 1.0 ) && ( check != lastcheck ) );
    splitter += 1.0;
    
    /* Error bounds for orientation and incircle tests. */
    resulterrbound = ( 3.0 + 8.0 * epsilon ) * epsilon;
    ccwerrboundA = ( 3.0 + 16.0 * epsilon ) * epsilon;
    ccwerrboundB = ( 2.0 + 12.0 * epsilon ) * epsilon;
    ccwerrboundC = ( 9.0 + 64.0 * epsilon ) * epsilon * epsilon;
    o3derrboundA = ( 7.0 + 56.0 * epsilon ) * epsilon;
    o3derrboundB = ( 3.0 + 28.0 * epsilon ) * epsilon;
    o3derrboundC = ( 26.0 + 288.0 * epsilon ) * epsilon * epsilon;
}

void vtkPowerCrustSurfaceReconstructionImpl::tetorthocenter ( double a[4],double b[4],double c[4],double d[4],double orthocenter[3], double *cnum )
{
    double xba, yba, zba, xca, yca, zca, xda, yda, zda, wba, wca, wda;
    double balength, calength, dalength;
    double xcrosscd, ycrosscd, zcrosscd;
    double xcrossdb, ycrossdb, zcrossdb;
    double xcrossbc, ycrossbc, zcrossbc;
    double denominator;
    double xcirca, ycirca, zcirca;
    double wa,wb,wc,wd;
    
    wa = a[0]*a[0] + a[1]*a[1] + a[2]*a[2] - a[3];
    wb = b[0]*b[0] + b[1]*b[1] + b[2]*b[2] - b[3];
    wc = c[0]*c[0] + c[1]*c[1] + c[2]*c[2] - c[3];
    wd = d[0]*d[0] + d[1]*d[1] + d[2]*d[2] - d[3];
    /* Use coordinates relative to point `a' of the tetrahedron. */
    xba = b[0] - a[0];
    yba = b[1] - a[1];
    zba = b[2] - a[2];
    wba = wb - wa;
    xca = c[0] - a[0];
    yca = c[1] - a[1];
    zca = c[2] - a[2];
    wca = wc - wa;
    xda = d[0] - a[0];
    yda = d[1] - a[1];
    zda = d[2] - a[2];
    wda = wd - wa;
    
    /* Squares of lengths of the edges incident to `a'. */
    balength = xba * xba + yba * yba + zba * zba - wba;
    calength = xca * xca + yca * yca + zca * zca - wca;
    dalength = xda * xda + yda * yda + zda * zda - wda;
    /* Cross products of these edges. */
    xcrosscd = yca * zda - yda * zca;
    ycrosscd = zca * xda - zda * xca;
    zcrosscd = xca * yda - xda * yca;
    xcrossdb = yda * zba - yba * zda;
    ycrossdb = zda * xba - zba * xda;
    zcrossdb = xda * yba - xba * yda;
    xcrossbc = yba * zca - yca * zba;
    ycrossbc = zba * xca - zca * xba;
    zcrossbc = xba * yca - xca * yba;
    
    /* Calculate the denominator of the formulae. */
#ifdef EXACT
    /* Use orient3d() from http://www.cs.cmu.edu/~quake/robust.html     */
    /*   to ensure a correctly signed (and reasonably accurate) result, */
    /*   avoiding any possibility of division by zero.                  */
    *cnum = orient3d ( b, c, d, a );
    denominator = 0.5 / ( *cnum );
#else
    /* Take your chances with floating-point roundoff. */
    denominator = 0.5 / ( xba * xcrosscd + yba * ycrosscd + zba * zcrosscd );
    
#endif
    
    /* Calculate offset (from `a') of circumcenter. */
    xcirca = ( balength * xcrosscd + calength * xcrossdb + dalength * xcrossbc ) *
    denominator;
    ycirca = ( balength * ycrosscd + calength * ycrossdb + dalength * ycrossbc ) *
    denominator;
    zcirca = ( balength * zcrosscd + calength * zcrossdb + dalength * zcrossbc ) *
    denominator;
    orthocenter[0] = xcirca;
    orthocenter[1] = ycirca;
    orthocenter[2] = zcirca;
}

void vtkPowerCrustSurfaceReconstructionImpl::tetcircumcenter ( double a[3],double b[3],double c[3],double d[3], double circumcenter[3],double *cond )
{
    double xba, yba, zba, xca, yca, zca, xda, yda, zda;
    double balength, calength, dalength;
    double xcrosscd, ycrosscd, zcrosscd;
    double xcrossdb, ycrossdb, zcrossdb;
    double xcrossbc, ycrossbc, zcrossbc;
    double denominator;
    double xcirca, ycirca, zcirca;
    
    /* Use coordinates relative to point `a' of the tetrahedron. */
    xba = b[0] - a[0];
    yba = b[1] - a[1];
    zba = b[2] - a[2];
    xca = c[0] - a[0];
    yca = c[1] - a[1];
    zca = c[2] - a[2];
    xda = d[0] - a[0];
    yda = d[1] - a[1];
    zda = d[2] - a[2];
    /* Squares of lengths of the edges incident to `a'. */
    balength = xba * xba + yba * yba + zba * zba;
    calength = xca * xca + yca * yca + zca * zca;
    dalength = xda * xda + yda * yda + zda * zda;
    /* Cross products of these edges. */
    xcrosscd = yca * zda - yda * zca;
    ycrosscd = zca * xda - zda * xca;
    zcrosscd = xca * yda - xda * yca;
    xcrossdb = yda * zba - yba * zda;
    ycrossdb = zda * xba - zba * xda;
    zcrossdb = xda * yba - xba * yda;
    xcrossbc = yba * zca - yca * zba;
    ycrossbc = zba * xca - zca * xba;
    zcrossbc = xba * yca - xca * yba;
    
    /* Calculate the denominator of the formulae. */
#ifdef EXACT
    /* Use orient3d() from http://www.cs.cmu.edu/~quake/robust.html     */
    /*   to ensure a correctly signed (and reasonably accurate) result, */
    /*   avoiding any possibility of division by zero.                  */
    *cond = orient3d ( b,c,d,a );
    denominator = 0.5 / ( *cond );
#else
    /* Take your chances with floating-point roundoff. */
    denominator = 0.5 / ( xba * xcrosscd + yba * ycrosscd + zba * zcrosscd );
#endif
    
    /* Calculate offset (from `a') of circumcenter. */
    xcirca = ( balength * xcrosscd + calength * xcrossdb + dalength * xcrossbc ) *
    denominator;
    ycirca = ( balength * ycrosscd + calength * ycrossdb + dalength * ycrossbc ) *
    denominator;
    zcirca = ( balength * zcrosscd + calength * zcrossdb + dalength * zcrossbc ) *
    denominator;
    circumcenter[0] = xcirca;
    circumcenter[1] = ycirca;
    circumcenter[2] = zcirca;
}

double vtkPowerCrustSurfaceReconstructionImpl::sqdist ( double a[3], double b[3] )
{
    /* returns the squared distance between a and b */
    return SQ ( a[0]-b[0] ) +SQ ( a[1]-b[1] ) +SQ ( a[2]-b[2] );
}

void vtkPowerCrustSurfaceReconstructionImpl::dir_and_dist ( double a[3], double b[3], double dir[3], double* dist )
{
    int k;
    
    for ( k=0; k<3; k++ ) dir[k] = b[k] - a[k];
    *dist = sqrt ( SQ ( dir[0] ) +SQ ( dir[1] ) +SQ ( dir[2] ) );
    for ( k=0; k<3; k++ ) dir[k] = dir[k] / ( *dist );
}

int vtkPowerCrustSurfaceReconstructionImpl::propagate()
{
    int pid = extract_max();
    if ( adjlist[pid].in > adjlist[pid].out )
        adjlist[pid].label = IN;
    else adjlist[pid].label = OUT;
    
    if ( pid != -1 )
    {
        opp_update ( pid );
        sym_update ( pid );
    }
    return pid;
}

void vtkPowerCrustSurfaceReconstructionImpl::opp_update ( int pi )
{
    plist *pindex;
    
    pindex = opplist[pi];
    while ( pindex!=NULL )
    {
        int npi = pindex->pid;
        if ( adjlist[npi].label == INIT ) /* not yet labeled */
        {
            if ( adjlist[npi].hid == 0 ) /* not in the heap */
            {
                if ( adjlist[pi].in > adjlist[pi].out )
                {
                    /* propagate in*cos to out */
                    adjlist[npi].out = ( -1.0 ) * adjlist[pi].in * pindex->angle;
                    insert_heap ( npi,adjlist[npi].out );
                }
                else if ( adjlist[pi].in < adjlist[pi].out )
                {
                    /* propagate out*cos to in */
                    adjlist[npi].in = ( -1.0 ) * adjlist[pi].out * pindex->angle;
                    insert_heap ( npi,adjlist[npi].in );
                }
            }
            else   /* in the heap */
            {
                int nhi = adjlist[npi].hid;
                if ( adjlist[pi].in > adjlist[pi].out )
                {
                    /* propagate in*cos to out */
                    double temp = ( -1.0 ) * adjlist[pi].in * pindex->angle;
                    if ( temp > adjlist[npi].out )
                    {
                        adjlist[npi].out = temp;
                        update_pri ( nhi,npi );
                    }
                }
                else if ( adjlist[pi].in < adjlist[pi].out )
                {
                    /* propagate out*cos to in */
                    double temp = ( -1.0 ) * adjlist[pi].out * pindex->angle;
                    if ( temp > adjlist[npi].in )
                    {
                        adjlist[npi].in = temp;
                        update_pri ( nhi,npi );
                    }
                }
            }
        }
        pindex = pindex->next;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::sym_update ( int pi )
{
    edgesimp *eindex;
    
    eindex = adjlist[pi].eptr;
    while ( eindex!=NULL )
    {
        int npi = eindex->pid;
        
        /* try to label deeply intersecting unlabeled neighbors */
        if ( ( adjlist[npi].label==INIT ) && ( eindex->angle > theta ) )
        {
            /* not yet labeled */
            if ( adjlist[npi].hid == 0 ) /* not in the heap */
            {
                if ( adjlist[pi].in > adjlist[pi].out )
                {
                    /* propagate in*cos to in */
                    adjlist[npi].in = adjlist[pi].in * eindex->angle;
                    insert_heap ( npi,adjlist[npi].in );
                }
                else if ( adjlist[pi].in < adjlist[pi].out )
                {
                    /* propagate out*cos to out */
                    adjlist[npi].out = adjlist[pi].out * eindex->angle;
                    insert_heap ( npi,adjlist[npi].out );
                }
            }
            else   /* in the heap */
            {
                int nhi = adjlist[npi].hid;
                if ( adjlist[pi].in > adjlist[pi].out )
                {
                    /* propagate in*cos to in */
                    double temp = adjlist[pi].in * eindex->angle;
                    if ( temp > adjlist[npi].in )
                    {
                        adjlist[npi].in = temp;
                        update_pri ( nhi,npi );
                    }
                }
                else if ( adjlist[pi].in < adjlist[pi].out )
                {
                    /* propagate out*cos to out */
                    double temp = adjlist[pi].out * eindex->angle;
                    if ( temp > adjlist[npi].out )
                    {
                        adjlist[npi].out = temp;
                        update_pri ( nhi,npi );
                    }
                }
            }
        }
        eindex = eindex->next;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::update_pri ( int hi, int pi )
{
    double pr;
    
    if ( ( heap_A[hi].pid != pi ) || ( adjlist[pi].hid != hi ) )
    {
        return;
    }
    if ( adjlist[pi].in==0.0 )
    {
        pr = adjlist[pi].out;
    }
    else if ( adjlist[pi].out == 0.0 )
    {
        pr = adjlist[pi].in;
    }
    else   /* both in/out nonzero */
    {
        if ( adjlist[pi].in > adjlist[pi].out )
        {
            pr =  adjlist[pi].in - adjlist[pi].out - 1;
        }
        else
        {
            pr = adjlist[pi].out - adjlist[pi].in - 1;
        }
    }
    update ( hi,pr );
}

void vtkPowerCrustSurfaceReconstructionImpl::label_unlabeled ( int num )
{
    plist *pindex;
    edgesimp *eindex;
    int opplabel;
    
    for ( int i = 0; i < num; i++ )
    {
        if ( adjlist[i].label == INIT ) /* pole i is unlabeled.. try to label now */
        {
            opplabel = INIT;
            pindex = opplist[i];
            if ( ( pindex == NULL ) && ( adjlist[i].eptr==NULL ) )
            {
                continue;
            }
            /* check whether there is opp pole */
            while ( pindex!=NULL ) /* opp pole */
            {
                int npi = pindex->pid;
                if ( adjlist[npi].label != INIT )
                {
                    if ( opplabel == INIT ) opplabel = adjlist[npi].label;
                    else if ( opplabel != adjlist[npi].label )
                    {
                        opplabel = INIT; /* ignore the label of opposite poles */
                    }
                }
                pindex = pindex->next;
            }
            
            double tangle = -3.0;
            double tangle1 = -3.0;
            eindex = adjlist[i].eptr;
            while ( eindex != NULL )
            {
                int npi = eindex->pid;
                if ( adjlist[npi].label == IN )
                {
                    if ( tangle < eindex->angle )
                    {
                        tangle = eindex->angle;
                    }
                }
                else if ( adjlist[npi].label == OUT )
                {
                    if ( tangle1 < eindex->angle )
                    {
                        tangle1 = eindex->angle;
                    }
                }
                eindex = eindex->next;
            }
            /* now tangle, tangle 1 are angles of most deeply interesecting in, out poles */
            if ( tangle == -3.0 ) /* there was no in poles */
            {
                if ( tangle1 == -3.0 ) /* there was no out poles */
                {
                    if ( opplabel == INIT ) /* cannot trust opp pole or no labeled opp pole */
                    {
                    }
                    else if ( opplabel == IN )
                    {
                        adjlist[i].label = OUT;
                    }
                    else  adjlist[i].label = IN;
                }
                else if ( tangle1 > deep ) /* interesecting deeply only out poles */
                {
                    adjlist[i].label = OUT;
                }
                else   /* no deeply intersecting poles . use opp pole */
                {
                    if ( opplabel == INIT ) /* cannot trust opp pole or no labeled opp pole */
                    {
                    }
                    else if ( opplabel == IN )
                    {
                        adjlist[i].label = OUT;
                    }
                    else  adjlist[i].label = IN;
                }
            }
            else if ( tangle1 == -3.0 ) /* there are in pole but no out pole */
            {
                if ( tangle > deep ) /* interesecting deeply only in poles */
                {
                    adjlist[i].label = IN;
                }
                else   /* no deeply intersecting poles . use opp pole */
                {
                    if ( opplabel == INIT ) /* cannot trust opp pole or no labeled opp pole */
                    {
                    }
                    else if ( opplabel == IN )
                    {
                        adjlist[i].label = OUT;
                    }
                    else  adjlist[i].label = IN;
                }
            }
            else   /* there are both in/out poles */
            {
                if ( tangle > deep )
                {
                    if ( tangle1 > deep ) /* intersecting both deeply */
                    {
                        /* use opp */
                        if ( opplabel == INIT ) /* cannot trust opp pole or no labeled opp pole */
                        {
                            /* then give label with bigger angle */
                            if ( tangle > tangle1 )
                            {
                                adjlist[i].label = IN;
                            }
                            else adjlist[i].label = OUT;
                        }
                        else if ( opplabel == IN )
                        {
                            adjlist[i].label = OUT;
                        }
                        else  adjlist[i].label = IN;
                    }
                    else   /* intersecting only in deeply */
                    {
                        adjlist[i].label = IN;
                    }
                }
                else if ( tangle1 > deep ) /* intersecting only out deeply */
                {
                    adjlist[i].label = OUT;
                }
                else   /* no deeply intersecting poles . use opp pole */
                {
                    if ( opplabel == INIT ) /* cannot trust opp pole or no labeled opp pole */
                    {
                    }
                    else if ( opplabel == IN )
                    {
                        adjlist[i].label = OUT;
                    }
                    else  adjlist[i].label = IN;
                }
            }
        }
    }
}

neighbor * vtkPowerCrustSurfaceReconstructionImpl::op_simp ( simplex *a, simplex *b )
{
    lookup ( a, b, simp )
}

neighbor * vtkPowerCrustSurfaceReconstructionImpl::op_vert ( simplex *a, site b )
{
    lookup ( a, b, vert )
}

void vtkPowerCrustSurfaceReconstructionImpl::connect ( simplex *s )
{
    /* make neighbor connections between newly created simplices incident to p */
    
    site xf, xb, xfi;
    simplex *sb, *sf, *seen;
    int i;
    neighbor *sn;
    
    if ( !s )
    {
        return;
    }
    assert ( !s->peak.vert && s->peak.simp->peak.vert==p && !op_vert ( s,p )->simp->peak.vert );
    if ( s->visit == pnum )
    {
        return;
    }
    s->visit = pnum;
    seen = s->peak.simp;
    xfi = op_simp ( seen, s )->vert;
    for ( i = 0, sn = s->neigh; i < cdim; i++, sn++ )
    {
        xb = sn->vert;
        if ( p == xb )
        {
            continue;
        }
        sb = seen;
        sf = sn->simp;
        xf = xfi;
        if ( !sf->peak.vert )   /* are we done already? */
        {
            sf = op_vert ( seen, xb )->simp;
            if ( sf->peak.vert )
            {
                continue;
            }
        }
        else
        {
            int LoopCounter = 0;
            do
            {
                if ( LoopCounter == 100 )
                {
                    ASSERT ( pcFALSE, "new adjacency failure!" );
                }
                xb = xf;
                xf = op_simp ( sf, sb )->vert;
                sb = sf;
                sf = op_vert ( sb, xb )->simp;
                LoopCounter++;
            }
            while ( sf->peak.vert );
        }
        
        sn->simp = sf;
        op_vert ( sf,xf )->simp = s;
        
        connect ( sf );
    }
}

simplex * vtkPowerCrustSurfaceReconstructionImpl::make_facets ( simplex *seen )
{
    /* visit simplices s with sees(p,s), and make a facet for every neighbor
     * of s not seen by p */
    simplex *n;
    neighbor *bn;
    int i;
    
    if ( !seen ) return NULL;
    seen->peak.vert = p;
    
    for ( i = 0, bn = seen->neigh; i < cdim; i++, bn++ )
    {
        n = bn->simp;
        if ( pnum != n->visit )
        {
            n->visit = pnum;
            if ( sees ( p,n ) ) make_facets ( n );
        }
        if ( n->peak.vert ) continue;
        copy_simp ( make_facets_ns,seen );
        make_facets_ns->visit = 0;
        make_facets_ns->peak.vert = 0;
        make_facets_ns->normal = 0;
        make_facets_ns->peak.simp = seen;
        /*      ns->Sb -= ns->neigh[i].basis->sqb; */
        NULLIFY ( basis_s,make_facets_ns->neigh[i].basis );
        make_facets_ns->neigh[i].vert = p;
        bn->simp = op_simp ( n,seen )->simp = make_facets_ns;
    }
    return make_facets_ns;
}

simplex * vtkPowerCrustSurfaceReconstructionImpl::extend_simplices ( simplex *s )
{
    /* p lies outside flat containing previous sites;
     * make p a vertex of every current simplex, and create some new simplices */
    int i;
    int ocdim = cdim - 1;
    simplex *ns;
    neighbor *nsn;
    
    if ( s->visit == pnum ) return s->peak.vert ? s->neigh[ocdim].simp : s;
    s->visit = pnum;
    s->neigh[ocdim].vert = p;
    NULLIFY ( basis_s,s->normal );
    NULLIFY ( basis_s,s->neigh[0].basis );
    if ( !s->peak.vert )
    {
        s->neigh[ocdim].simp = extend_simplices ( s->peak.simp );
        return s;
    }
    else
    {
        copy_simp ( ns,s );
        s->neigh[ocdim].simp = ns;
        ns->peak.vert = NULL;
        ns->peak.simp = s;
        ns->neigh[ocdim] = s->peak;
        inc_ref ( basis_s,s->peak.basis );
        for ( i=0,nsn=ns->neigh; i<cdim; i++,nsn++ )
            nsn->simp = extend_simplices ( nsn->simp );
    }
    return ns;
}

simplex * vtkPowerCrustSurfaceReconstructionImpl::search ( simplex *root )
{
    /* return a simplex s that corresponds to a facet of the
     * current hull, and sees(p, s) */
    
    simplex *s;
    neighbor *sn;
    int i;
    long tms = 0;
    
    if ( !st_search )
    {
        st_search = ( simplex ** ) malloc ( ( search_ss + MAXDIM + 1 ) *sizeof ( simplex* ) );
    }
    push ( root->peak.simp, st_search, tms );
    root->visit = pnum;
    if ( !sees ( p,root ) )
        for ( i=0,sn=root->neigh; i<cdim; i++,sn++ )
            push ( sn->simp, st_search, tms );
    while ( tms )
    {
        if ( tms>search_ss )
        {
            st_search = ( simplex** ) realloc ( st_search, ( ( search_ss += search_ss ) +MAXDIM+1 ) *sizeof ( simplex* ) );
            assert ( st_search );
        }
        pop ( s, st_search, tms );
        if ( s->visit == pnum )
            continue;
        s->visit = pnum;
        if ( !sees ( p, s ) )
            continue;
        if ( !s->peak.vert )
        {
            return s;
        }
        for ( i=0, sn=s->neigh; i<cdim; i++,sn++ )
            push ( sn->simp, st_search, tms );
    }
    return NULL;
}

point vtkPowerCrustSurfaceReconstructionImpl::get_another_site ( void )
{
    point pnext;
    
    if ( ! ( ++scount % 1000 ) )
    {
        
    }
    pnext = ( this->*get_site ) ();
    
    if ( !pnext )
    {
        return NULL;
    }
    pnum = ( this->*site_num ) ( pnext ) + 2;
    return pnext;
}

void vtkPowerCrustSurfaceReconstructionImpl::buildhull ( simplex *root )
{
    while ( cdim < rdim )
    {
        p = get_another_site();
        if ( !p )
        {
            return;
        }
        if ( out_of_flat ( root, p ) )
        {
            extend_simplices ( root );
        }
        else
        {
            connect ( make_facets ( search ( root ) ) );
        }
    }
    while ( ( p = get_another_site() ) != NULL )
    {
        connect ( make_facets ( search ( root ) ) );
    }
}

int vtkPowerCrustSurfaceReconstructionImpl::reduce ( basis_s **v, point p, simplex *s, int k )
{
    point   z;
    point   tt = s->neigh[0].vert;
    
    if ( !*v ) NEWLRC ( basis_s, ( *v ) )
        else ( *v )->lscale = 0;
    z = VB ( *v );
    if ( vd || power_diagram )
    {
        if ( p==infinity ) memcpy ( *v,infinity_basis,basis_s_size );
        else
        {
            trans ( z,p,tt );
            lift ( z,s );
        }
    }
    else trans ( z,p,tt );
    return reduce_inner ( *v,s,k );
}

void vtkPowerCrustSurfaceReconstructionImpl::get_basis_sede ( simplex *s )
{
    int k=1;
    neighbor *sn = s->neigh+1,
    *sn0 = s->neigh;
    
    if ( ( vd || power_diagram ) && sn0->vert == infinity && cdim >1 )
    {
        SWAP ( neighbor, *sn0, *sn );
        NULLIFY ( basis_s,sn0->basis );
        sn0->basis = tt_basisp;
        tt_basisp->ref_count++;
    }
    else
    {
        if ( !sn0->basis )
        {
            sn0->basis = tt_basisp;
            tt_basisp->ref_count++;
        }
        else while ( k < cdim && sn->basis )
        {
            k++;
            sn++;
        }
    }
    while ( k<cdim )
    {
        NULLIFY ( basis_s,sn->basis );
        reduce ( &sn->basis,sn->vert,s,k );
        k++;
        sn++;
    }
}

int vtkPowerCrustSurfaceReconstructionImpl::out_of_flat ( simplex *root, point p )
{
    if ( !p_neigh.basis )
        p_neigh.basis = ( basis_s* ) malloc ( basis_s_size );
    
    p_neigh.vert = p;
    cdim++;
    root->neigh[cdim-1].vert = root->peak.vert;
    NULLIFY ( basis_s,root->neigh[cdim-1].basis );
    get_basis_sede ( root );
    if ( ( vd || power_diagram ) && root->neigh[0].vert == infinity ) return 1;
    reduce ( &p_neigh.basis,p,root,cdim );
    if ( p_neigh.basis->sqa != 0 ) return 1;
    cdim--;
    return 0;
}

double vtkPowerCrustSurfaceReconstructionImpl::cosangle_sq ( basis_s* v, basis_s* w )
{
    double dd;
    point vv = v->vecs, wv = w->vecs;
    dd = Vec_dot ( vv,wv );
    return dd*dd/Norm2 ( vv ) /Norm2 ( wv );
}

int vtkPowerCrustSurfaceReconstructionImpl::check_perps ( simplex *s )
{
    point z, y;
    point tt;
    
    for ( int i = 1; i < cdim; i++ ) if ( NEARZERO ( s->neigh[i].basis->sqb ) ) return 0;
    if ( !check_perps_b )
    {
        check_perps_b = ( basis_s* ) malloc ( basis_s_size );
        assert ( check_perps_b );
    }
    else check_perps_b->lscale = 0;
    z = VB ( check_perps_b );
    tt = s->neigh[0].vert;
    for ( int i = 1; i < cdim; i++ )
    {
        y = s->neigh[i].vert;
        if ( ( vd || power_diagram ) && y==infinity ) memcpy ( check_perps_b, infinity_basis, basis_s_size );
        else
        {
            trans ( z,y,tt );
            lift ( z,s );
        }
        if ( s->normal && cosangle_sq ( check_perps_b,s->normal ) >b_err_min_sq )
        {
            return 0;
        }
        for ( int j = i + 1; j < cdim; j++ )
        {
            if ( cosangle_sq ( check_perps_b,s->neigh[j].basis ) >b_err_min_sq )
            {
                return 0;
            }
        }
    }
    return 1;
}

void vtkPowerCrustSurfaceReconstructionImpl::get_normal_sede ( simplex *s )
{
    neighbor *rn;
    int i, j;
    
    get_basis_sede ( s );
    if ( rdim == 3 && cdim == 3 )
    {
        point c;
        point a = VB ( s->neigh[1].basis );
        point b = VB ( s->neigh[2].basis );
        NEWLRC ( basis_s,s->normal );
        c = VB ( s->normal );
        c[0] = a[1]*b[2] - a[2]*b[1];
        c[1] = a[2]*b[0] - a[0]*b[2];
        c[2] = a[0]*b[1] - a[1]*b[0];
        s->normal->sqb = Norm2 ( c );
        for ( i=cdim+1,rn = ch_root->neigh+cdim-1; i; i--, rn-- )
        {
            for ( j = 0; j<cdim && rn->vert != s->neigh[j].vert; j++ );
            if ( j<cdim ) continue;
            if ( rn->vert==infinity )
            {
                if ( c[2] > -b_err_min ) continue;
            }
            else  if ( !sees ( rn->vert,s ) ) continue;
            c[0] = -c[0];
            c[1] = -c[1];
            c[2] = -c[2];
            break;
        }
        return;
    }
    
    for ( i = cdim + 1, rn = ch_root->neigh+cdim-1; i; i--, rn-- )
    {
        for ( j = 0; j<cdim && rn->vert != s->neigh[j].vert; j++ );
        if ( j<cdim ) continue;
        reduce ( &s->normal,rn->vert,s,cdim );
        if ( s->normal->sqb != 0 ) break;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::get_normal ( simplex *s )
{
    get_normal_sede ( s );
    return;
}

int vtkPowerCrustSurfaceReconstructionImpl::sees ( site p, simplex *s )
{
    point tt, zz;
    double dd, dds;
    int i;
    
    if ( !seesB )
    {
        seesB = ( basis_s* ) malloc ( basis_s_size );
        assert ( seesB );
    }
    else
        seesB->lscale = 0;
    zz = VB ( seesB );
    if ( cdim == 0 )
        return 0;
    if ( !s->normal )
    {
        get_normal_sede ( s );
        for ( i = 0; i < cdim; i++ )
            NULLIFY ( basis_s, s->neigh[i].basis );
    }
    tt = s->neigh[0].vert;
    if ( vd || power_diagram )
    {
        if ( p == infinity )
            memcpy ( seesB, infinity_basis, basis_s_size );
        else
        {
            trans ( zz,p,tt );
            lift ( zz,s );
        }
    }
    else
        trans ( zz,p,tt );
    for ( i = 0; i < 3; i++ )
    {
        dd = Vec_dot ( zz,s->normal->vecs );
        if ( dd == 0.0 )
        {
            return 0;
        }
        dds = dd*dd/s->normal->sqb/Norm2 ( zz );
        if ( dds > b_err_min_sq )
            return ( dd < 0 );
        get_basis_sede ( s );
        reduce_inner ( seesB, s, cdim );
    }
    return 0;
}

double vtkPowerCrustSurfaceReconstructionImpl::radsq ( simplex *s )
{
    point n;
    neighbor *sn;
    int i;
    
    /* square of ratio of circumcircle radius to max edge length for Delaunay tetrahedra */
    
    for ( i=0,sn=s->neigh; i<cdim; i++,sn++ )
        if ( sn->vert == infinity ) return Huge;
    
    if ( !s->normal ) get_normal_sede ( s );
    
    /* compute circumradius */
    n = s->normal->vecs;
    
    if ( NEARZERO ( n[rdim-1] ) )
    {
        return Huge;
    }
    
    return Vec_dot_pdim ( n,n ) /4/n[rdim-1]/n[rdim-1];
}

void * vtkPowerCrustSurfaceReconstructionImpl::zero_marks ( simplex * s, void *dum )
{
    s->mark = 0;
    return NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::one_marks ( simplex * s, void *dum )
{
    s->mark = 1;
    return NULL;
}

int vtkPowerCrustSurfaceReconstructionImpl::alph_test ( simplex *s, int i, void *alphap )
{
    /*returns 1 if not an alpha-facet */
    simplex *si;
    neighbor *scn, *sin;
    int k;
    
    if ( alphap )
    {
        alpha_test_alpha=* ( double* ) alphap;
        if ( !s ) return 1;
    }
    if ( i==-1 ) return 0;
    
    si = s->neigh[i].simp;
    scn = s->neigh+cdim-1;
    sin = s->neigh+i;
    int nsees = 0;
    
    for ( k=0; k<cdim; k++ ) if ( s->neigh[k].vert==infinity && k!=i ) return 1;
    double rs = radsq ( s );
    double rsi = radsq ( si );
    
    if ( rs < alpha_test_alpha &&  rsi < alpha_test_alpha ) return 1;
    
    swap_points ( scn->vert,sin->vert );
    NULLIFY ( basis_s, s->neigh[i].basis );
    cdim--;
    get_basis_sede ( s );
    reduce ( &s->normal,infinity,s,cdim );
    double rsfi = radsq ( s );
    
    for ( k=0; k<cdim; k++ ) if ( si->neigh[k].simp==s ) break;
    
    int ssees = sees ( scn->vert,s );
    if ( !ssees ) nsees = sees ( si->neigh[k].vert,s );
    swap_points ( scn->vert,sin->vert );
    cdim++;
    NULLIFY ( basis_s, s->normal );
    NULLIFY ( basis_s, s->neigh[i].basis );
    
    if ( ssees ) return alpha_test_alpha<rs;
    if ( nsees ) return alpha_test_alpha<rsi;
    
    assert ( rsfi<=rs+FLT_EPSILON && rsfi<=rsi+FLT_EPSILON );
    
    return alpha_test_alpha<=rsfi;
}

void * vtkPowerCrustSurfaceReconstructionImpl::conv_facetv ( simplex *s, void *dum )
{
    for ( int i = 0; i < cdim; i++ )
        if ( s->neigh[i].vert == infinity )
        {
            return s;
        }
    return NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::mark_points ( simplex *s, void *dum )
{
    int i, snum;
    neighbor *sn;
    
    for ( i=0,sn=s->neigh; i<cdim; i++,sn++ )
    {
        if ( sn->vert==infinity ) continue;
        snum = ( this->*site_num ) ( sn->vert );
        if ( s->mark ) mo[snum] = 1;
        else mi[snum] = 1;
    }
    return NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::visit_outside_ashape ( simplex *root, visit_func visit )
{
    return visit_triang_gen ( ( simplex* ) visit_hull ( root, &vtkPowerCrustSurfaceReconstructionImpl::conv_facetv ), visit, &vtkPowerCrustSurfaceReconstructionImpl::alph_test );
}

int vtkPowerCrustSurfaceReconstructionImpl::check_ashape ( simplex *root, double alpha )
{
    for ( int i = 0; i < MAXPOINTS; i++ )
    {
        mi[i] = mo[i] = 0;
    }
    
    visit_hull ( root, &vtkPowerCrustSurfaceReconstructionImpl::zero_marks );
    
    alph_test ( 0, 0, &alpha );
    visit_outside_ashape ( root, &vtkPowerCrustSurfaceReconstructionImpl::one_marks );
    
    visit_hull ( root, &vtkPowerCrustSurfaceReconstructionImpl::mark_points );
    
    for ( int i = 0; i < MAXPOINTS; i++ ) if ( mo[i] && !mi[i] )
    {
        return 0;
    }
    
    return 1;
}

simplex * vtkPowerCrustSurfaceReconstructionImpl::build_convex_hull ( short dim, short vdd )
{
    /*
     get_s     returns next site each call;
     hull construction stops when NULL returned;
     site_numm returns number of site when given site;
     dim       dimension of point set;
     vdd       if (vdd) then return Delaunay triangulation
     */
    
    simplex *s, *root;
    
    cdim = 0;
    get_site = &vtkPowerCrustSurfaceReconstructionImpl::get_next_site;
    site_num = &vtkPowerCrustSurfaceReconstructionImpl::site_numm;
    pdim = dim;
    vd = vdd;
    
    exact_bits = ( int ) ( DBL_MANT_DIG*log ( FLT_RADIX ) /log ( 2.0 ) ); // cast to int added by TJH // EPRO added
    
    b_err_min = DBL_EPSILON*MAXDIM* ( 1 << MAXDIM ) * MAXDIM * 3.01;
    
    b_err_min_sq = b_err_min * b_err_min;
    
    assert ( get_site != NULL );
    assert ( site_num != NULL );
    
    rdim = vd ? pdim+1 : pdim;
    
    if ( rdim > MAXDIM )
        ASSERT ( pcFALSE, "dimension bound MAXDIM exceeded" );
    
    site_size = sizeof ( Coord ) *pdim;
    basis_vec_size = sizeof ( Coord ) *rdim;
    basis_s_size = sizeof ( basis_s ) + ( 2*rdim-1 ) *sizeof ( Coord );
    simplex_size = sizeof ( simplex ) + ( rdim-1 ) *sizeof ( neighbor );
    Tree_size = sizeof ( Tree );
    fg_size = sizeof ( fg );
    
    
    root = NULL;
    if ( vd || power_diagram )
    {
        p = infinity;
        NEWLRC ( basis_s, infinity_basis );
        infinity_basis->vecs[2*rdim-1] = infinity_basis->vecs[rdim-1] = 1;
        infinity_basis->sqa = infinity_basis->sqb = 1;
    }
    else if ( ! ( p = ( this->*get_site ) () ) ) return 0;
    
    NEWL ( simplex, root );
    
    ch_root = root;
    
    copy_simp ( s,root );
    root->peak.vert = p;
    root->peak.simp = s;
    s->peak.simp = root;
    
    buildhull ( root );
    return root;
}

void vtkPowerCrustSurfaceReconstructionImpl::free_hull_storage ( void )
{
    free_basis_s_storage();
    free_simplex_storage();
    free_Tree_storage();
    free_fg_storage();
}

void * vtkPowerCrustSurfaceReconstructionImpl::compute_vv ( simplex *s, void *p )
{
    /* computes Voronoi vertices  */
    point v[MAXDIM];
    int inf = 0;
    double cc[3], cond, ta[4][3];
    
    if ( !s ) return NULL;
    
    for ( int j = 0; j < cdim; j++ )
    {
        v[j] = s->neigh[j].vert;
        /* v[j] stores coordinates of j'th vertex of simplex s; j=0..3 */
        if ( v[j]==infinity ) /* means simplex s is on the convex hull */
        {
            inf = 1;
            break; /* skip the rest of the for loop, ignore convex hull faces (= bounding box ) */
        }
        for ( int k = 0; k < cdim - 1; k++ )
        {
            ta[j][k] = v[j][k]/mult_up; /* restore original coords   */
        }
    }
    
    if ( !inf ) /* if not faces on convex hull, compute circumcenter*/
    {
        tetcircumcenter ( ta[0], ta[1], ta[2], ta[3], cc, &cond );
        if ( cond!=0 ) /* ignore them if cond = 0 */
        {
            s->isVvNull = false;
            for ( int k = 0; k < cdim - 1; k++ )
            {
                s->vv[k] = ta[0][k]+cc[k];
            }
            s->status = VV;
        }
        else
        {
            s->isVvNull = true;
            s->status = SLV;
        }
    }
    else   /* if on conv hull */
    {
        s->status = CNV;
    }
    
    /* computing poles */
    for ( int j = 0; j < cdim; j++ ) /* compute 1st pole for vertex j */
    {
        int i = ( this->*site_num ) ( s->neigh[j].vert );
        if ( i ==-1 ) continue;
        
        /* Ignore poles that are too far away to matter - a relic of the
         original California-style crust. Probably no longer needed */
        if ( ( s->neigh[j].vert[0] > omaxs[0] ) ||
            ( s->neigh[j].vert[0] < omins[0] ) ||
            ( s->neigh[j].vert[1] > omaxs[1] ) ||
            ( s->neigh[j].vert[1] < omins[1] ) ||
            ( s->neigh[j].vert[2] > omaxs[2] ) ||
            ( s->neigh[j].vert[2] < omins[2] ) )
        {
            pole1[i]=NULL;
            continue;
        }
        else
        {
            if ( pole1[i]==NULL )
            {
                /* the vertex i is encountered for the 1st time */
                if ( s->status==VV ) /* we don't store infinite poles */
                {
                    pole1[i]=s;
                    continue;
                }
            }
            if ( ( s->status == VV ) && ( pole1[i]->status == VV ) )
            {
                if ( sqdist ( pole1[i]->vv,ta[j] ) < sqdist ( s->vv,ta[j] ) )
                {
                    pole1[i]=s; /* update 1st pole */
                }
            }
        }
    }
    
    return NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::compute_pole2 ( simplex *s, void *p )
{
    point v[MAXDIM];
    int inf = 0;
    double a[3] = {0, 0, 0};
    site t;
    double dir_s[3], dir_p[3], dist_s,dist_p;
    
    if ( p )
    {
        if ( !s ) return NULL;
    }
    
    for ( int j = 0; j < cdim; j++ )
    {
        v[j] = s->neigh[j].vert;
        int i = ( this->*site_num ) ( v[j] );
        if ( i == -1 ) inf = 1;
    }
    
    double cos_2r = cos ( 2 * est_r );
    
    for ( int j = 0; j < cdim; j++ ) /* compute 2nd poles */
    {
        t = s->neigh[j].vert;
        int i = ( this->*site_num ) ( t );
        if ( i < 0 ) continue; /* not a vertex */
        if ( inf ) /* on conv hull */
        {
            if ( s->status == CNV )
            {
                continue;
            }
        }
        if ( !pole1[i] )
        {
            continue;
        }
        
        if ( pole1[i]->isVvNull ) //pole1[i]->vv==NULL
        {
            continue;
        }
        
        if ( s->isVvNull ) //!s->vv
        {
            if ( s->status != SLV )
                continue;
        }
        
        for ( int k = 0; k < cdim - 1; k++ ) /* a stores orig vertex coord */
        {
            a[k]=t[k]/mult_up;
        }
        
        /* compute direction and length of vector from sample to first pole */
        dir_and_dist ( a,pole1[i]->vv,dir_p,&dist_p );
        
        /* We have a vertex, and there is a good first pole. */
        if ( ( s->status==VV ) && ( pole1[i]->status==VV ) )
        {
            /* make direction vector from sample to this Voronoi vertex */
            dir_and_dist ( a, s->vv, dir_s, &dist_s );
            
            /* cosine of angle between angle to vertex and angle to pole */
            double cos_sp = dir_s[0]*dir_p[0] + dir_s[1]*dir_p[1] + dir_s[2]*dir_p[2];
            
            /* if there is an estimate for r, use it to estimate lfs */
            if ( est_r < 1.0 )
            {
                /* near vertices - should be close to sample (a) */
                if ( ( cos_sp < cos_2r ) && ( cos_sp > -cos_2r ) )
                {
                    /* use to get lower bound on lfs */
                    double est_lfs = dist_s /est_r * ( ( sqrt ( 1- cos_sp*cos_sp ) ) - est_r );
                    if ( est_lfs > lfs_lb[i] ) lfs_lb[i] = est_lfs;
                }
            }
            else
            {
                lfs_lb[i] = 0;
            }
            
            if ( cos_sp > 0 )
            {
                /* s->vv is in the same side of pole1  */
                continue;
            }
            
            /* s->vv is a candidate for pole2 */
            
            if ( !pole2[i] )
            {
                /* 1st pole2 candidate for vertex i */
                pole2[i]=s;
                continue;
            }
            else if ( !pole2[i]->vv ) /* 2nd pole points null */
            {
                continue;
            }
            else if ( ( pole2[i]->status == VV ) && ( sqdist ( a,pole2[i]->vv ) <sqdist ( a,s->vv ) ) )
                pole2[i]=s; /* update 2nd pole */
            
        }
    }
    
    return NULL;
}

int vtkPowerCrustSurfaceReconstructionImpl::close_pole ( double* v, double* p, double lfs_lb )
{
    return ( sqdist ( v, p ) < lfs_lb * lfs_lb );
}

int vtkPowerCrustSurfaceReconstructionImpl::antiLabel ( int label )
{
    if ( label == IN ) return ( OUT );
    if ( label == OUT ) return ( IN );
    return ( label );
}

double vtkPowerCrustSurfaceReconstructionImpl::computePoleAngle ( simplex* pole1, simplex* pole2, double* samp )
{
    return ( ( ( pole1->vv[0]-samp[0] ) * ( pole2->vv[0]-samp[0] ) +
              ( pole1->vv[1]-samp[1] ) * ( pole2->vv[1]-samp[1] ) +
              ( pole1->vv[2]-samp[2] ) * ( pole2->vv[2]-samp[2] ) ) /
            ( sqrt ( SQ ( pole1->vv[0]-samp[0] ) + SQ ( pole1->vv[1]-samp[1] ) + SQ ( pole1->vv[2]-samp[2] ) ) *
             sqrt ( SQ ( pole2->vv[0]-samp[0] ) + SQ ( pole2->vv[1]-samp[1] ) + SQ ( pole2->vv[2]-samp[2] ) ) ) );
}

void vtkPowerCrustSurfaceReconstructionImpl::newOpposite ( int p1index, int p2index, double pole_angle )
{
    plist* newplist;
    newplist = ( plist * ) malloc ( sizeof ( plist ) );
    newplist->pid = p2index;
    newplist->angle = pole_angle;
    newplist->next = opplist[p1index];
    opplist[p1index] = newplist;
    if ( adjlist[p1index].oppradius > adjlist[p2index].sqradius )
    {
        assert ( adjlist[p2index].sqradius > 0.0 );
        adjlist[p1index].oppradius = adjlist[p2index].sqradius;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::outputPole ( simplex* pole, int poleid, double* samp, int* num_poles,double distance )
{
    double r2 = SQ ( pole->vv[0]-samp[0] ) + SQ ( pole->vv[1]-samp[1] ) + SQ ( pole->vv[2]-samp[2] );
    
    double weight = SQ ( pole->vv[0] ) +SQ ( pole->vv[1] ) +SQ ( pole->vv[2] )- r2;
    
    pole->status = POLE_OUTPUT;
    pole->poleindex = poleid;
    
    vtk_medial_surface->GetPoints()->InsertNextPoint ( pole->vv[0],pole->vv[1], pole->vv[2] );
    
    vtk_medial_surface->GetPointData()->GetScalars()->InsertNextTuple1 ( weight );
    
    /* remember squared radius */
    adjlist[poleid].sqradius = r2;
    adjlist[poleid].samp_distance=distance;
    
    /* initialize perp dist to MA */
    adjlist[poleid].oppradius = r2;
    
    /* initialize */
    adjlist[poleid].grafindex = -1;
    
    /* keep count! */
    ( *num_poles ) ++;
}

Tree * vtkPowerCrustSurfaceReconstructionImpl::splay ( site i, Tree *t )
{
    Tree N, *l, *r, *y;
    
    if ( !t ) return t;
    N.left = N.right = NULL;
    l = r = &N;
    int l_size = 0;
    int r_size = 0;
    
    for ( ; ; )
    {
        int comp = compare ( i, t->key );
        if ( comp < 0 )
        {
            if ( !t->left ) break;
            if ( compare ( i, t->left->key ) < 0 )
            {
                y = t->left;                           /* rotate right */
                t->left = y->right;
                y->right = t;
                t->size = node_size ( t->left ) + node_size ( t->right ) + 1;
                t = y;
                if ( !t->left ) break;
            }
            r->left = t;                               /* link right */
            r = t;
            t = t->left;
            r_size += 1+node_size ( r->right );
        }
        else if ( comp > 0 )
        {
            if ( !t->right ) break;
            if ( compare ( i, t->right->key ) > 0 )
            {
                y = t->right;                          /* rotate left */
                t->right = y->left;
                y->left = t;
                t->size = node_size ( t->left ) + node_size ( t->right ) + 1;
                t = y;
                if ( !t->right ) break;
            }
            l->right = t;                              /* link left */
            l = t;
            t = t->right;
            l_size += 1+node_size ( l->left );
        }
        else break;
    }
    l_size += node_size ( t->left ); /* Now l_size and r_size are the sizes of */
    r_size += node_size ( t->right ); /* the left and right trees we just built.*/
    t->size = l_size + r_size + 1;
    
    l->right = r->left = NULL;
    
    /* The following two loops correct the size fields of the right path  */
    /* from the left child of the root and the right path from the left   */
    /* child of the root.                                                 */
    for ( y = N.right; y != NULL; y = y->right )
    {
        y->size = l_size;
        l_size -= 1+node_size ( y->left );
    }
    for ( y = N.left; y != NULL; y = y->left )
    {
        y->size = r_size;
        r_size -= 1+node_size ( y->right );
    }
    
    l->right = t->left;                                /* assemble */
    r->left = t->right;
    t->left = N.right;
    t->right = N.left;
    
    return t;
}

Tree * vtkPowerCrustSurfaceReconstructionImpl::insert ( site i, Tree * t )
{
    /* Insert key i into the tree t, if it is not already there. */
    /* Return a pointer to the resulting tree.                   */
    
    Tree *new_tree;
    
    if ( t != NULL )
    {
        t = splay ( i,t );
        if ( compare ( i, t->key ) ==0 )
        {
            return t;  /* it's already there */
        }
    }
    NEWL ( Tree, new_tree )
    if ( !t )
    {
        new_tree->left = new_tree->right = NULL;
    }
    else if ( compare ( i, t->key ) < 0 )
    {
        new_tree->left = t->left;
        new_tree->right = t;
        t->left = NULL;
        t->size = 1+node_size ( t->right );
    }
    else
    {
        new_tree->right = t->right;
        new_tree->left = t;
        t->right = NULL;
        t->size = 1+node_size ( t->left );
    }
    new_tree->key = i;
    new_tree->size = 1 + node_size ( new_tree->left ) + node_size ( new_tree->right );
    return new_tree;
}

void vtkPowerCrustSurfaceReconstructionImpl::free_heap ()
{
    free ( heap_A );
}

void vtkPowerCrustSurfaceReconstructionImpl::init_heap ( int num )
{
    heap_A = ( heap_array * ) calloc ( num + 1, sizeof ( heap_array ) ); // EPRO added
    heap_size = 0;
    heap_length = num;
}

void vtkPowerCrustSurfaceReconstructionImpl::heapify ( int hi )
{
    int largest;
    
    if ( ( LEFT ( hi ) <= heap_size ) && ( heap_A[LEFT ( hi )].pri > heap_A[hi].pri ) )
        largest = LEFT ( hi );
    else largest = hi;
    
    if ( ( RIGHT ( hi ) <= heap_size ) && ( heap_A[RIGHT ( hi )].pri > heap_A[largest].pri ) )
        largest = RIGHT ( hi );
    
    if ( largest != hi )
    {
        int temp = heap_A[hi].pid;
        heap_A[hi].pid = heap_A[largest].pid;
        adjlist[heap_A[hi].pid].hid = hi;
        heap_A[largest].pid = temp;
        adjlist[heap_A[largest].pid].hid = largest;
        double td =  heap_A[hi].pri;
        heap_A[hi].pri = heap_A[largest].pri;
        heap_A[largest].pri = td;
        heapify ( largest );
    }
}

int vtkPowerCrustSurfaceReconstructionImpl::extract_max()
{
    if ( heap_size < 1 ) return -1;
    int max = heap_A[1].pid;
    heap_A[1].pid = heap_A[heap_size].pid;
    heap_A[1].pri = heap_A[heap_size].pri;
    adjlist[heap_A[1].pid].hid = 1;
    heap_size--;
    heapify ( 1 );
    return max;
}

int vtkPowerCrustSurfaceReconstructionImpl::insert_heap ( int pi, double pr )
{
    heap_size++;
    int i = heap_size;
    while ( ( i > 1 ) && ( heap_A[PARENT ( i )].pri < pr ) )
    {
        heap_A[i].pid = heap_A[PARENT ( i )].pid;
        heap_A[i].pri = heap_A[PARENT ( i )].pri;
        adjlist[heap_A[i].pid].hid = i;
        i = PARENT ( i );
    };
    heap_A[i].pri = pr;
    heap_A[i].pid = pi;
    adjlist[pi].hid = i;
    return i;
}

void vtkPowerCrustSurfaceReconstructionImpl::update ( int hi, double pr )
{
    heap_A[hi].pri = pr;
    int pi = heap_A[hi].pid;
    
    if ( pr > heap_A[PARENT ( hi )].pri )
    {
        int i = hi;
        while ( ( i>1 ) && ( heap_A[PARENT ( i )].pri < pr ) )
        {
            heap_A[i].pid = heap_A[PARENT ( i )].pid;
            heap_A[i].pri = heap_A[PARENT ( i )].pri;
            adjlist[heap_A[i].pid].hid = i;
            i = PARENT ( i );
        };
        heap_A[i].pri = pr;
        heap_A[i].pid = pi;
        adjlist[pi].hid = i;
    }
    else heapify ( hi );
}

void * vtkPowerCrustSurfaceReconstructionImpl::visit_triang_gen ( simplex *s, visit_func visit, test_func test )
{
    /* starting at s, visit simplices t such that test(s,i,0) is true,
     * and t is the i'th neighbor of s;
     * apply visit function to all visited simplices;
     * when visit returns nonNULL, exit and return its value */
    neighbor *sn;
    void *v;
    simplex *t;
    int i;
    long tms = 0;
    
    visit_triang_gen_vnum--;
    if ( !st_visit_triang_gen )
    {
        st_visit_triang_gen = ( simplex** ) malloc ( ( visit_triang_gen_ss + MAXDIM + 1 ) * sizeof ( simplex* ) );
        assert ( st_visit_triang_gen );
    }
    if ( s ) push ( s, st_visit_triang_gen, tms );
    while ( tms )
    {
        if ( tms > visit_triang_gen_ss )
        {
            st_visit_triang_gen = ( simplex** ) realloc ( st_visit_triang_gen, ( ( visit_triang_gen_ss += visit_triang_gen_ss ) + MAXDIM + 1 ) * sizeof ( simplex* ) );
            assert ( st_visit_triang_gen );
        }
        pop ( t, st_visit_triang_gen, tms );
        if ( !t || t->visit == visit_triang_gen_vnum ) continue;
        t->visit = visit_triang_gen_vnum;
        if ( ( v = ( this->*visit ) ( t, 0 ) ) != NULL )
        {
            return v;
        }
        for ( i=-1,sn = t->neigh-1; i<cdim; i++,sn++ )
            if ( ( sn->simp->visit != visit_triang_gen_vnum ) && sn->simp && ( this->*test ) ( t, i, 0 ) )
                push ( sn->simp, st_visit_triang_gen, tms );
    }
    return NULL;
}

int vtkPowerCrustSurfaceReconstructionImpl::truet ( simplex *s, int i, void *dum )
{
    return 1;
}

void * vtkPowerCrustSurfaceReconstructionImpl::visit_triang ( simplex *root, visit_func visit )
{
    return visit_triang_gen ( root, visit, &vtkPowerCrustSurfaceReconstructionImpl::truet );
}

int vtkPowerCrustSurfaceReconstructionImpl::hullt ( simplex *s, int i, void *dummy )
{
    return i > -1;
}

void * vtkPowerCrustSurfaceReconstructionImpl::facet_test ( simplex *s, void *dummy )
{
    return ( !s->peak.vert ) ? s : NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::visit_hull ( simplex *root, visit_func visit )
{
    return visit_triang_gen ( ( simplex* ) visit_triang ( root, &vtkPowerCrustSurfaceReconstructionImpl::facet_test ), visit, &vtkPowerCrustSurfaceReconstructionImpl::hullt );
}

Coord vtkPowerCrustSurfaceReconstructionImpl::Vec_dot ( point x, point y )
{
    Coord sum = 0;
    for ( int i = 0; i < rdim; i++ ) sum += x[i] * y[i];
    return sum;
}

Coord vtkPowerCrustSurfaceReconstructionImpl::Vec_dot_pdim ( point x, point y )
{
    Coord sum = 0;
    for ( int i = 0; i < pdim; i++ ) sum += x[i] * y[i];
    return sum;
}

Coord vtkPowerCrustSurfaceReconstructionImpl::Norm2 ( point x )
{
    Coord sum = 0;
    for ( int i = 0; i < rdim; i++ ) sum += x[i] * x[i];
    return sum;
}

void vtkPowerCrustSurfaceReconstructionImpl::Ax_plus_y ( Coord a, point x, point y )
{
    for ( int i = 0; i < rdim; i++ )
    {
        *y++ += a * *x++;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::Ax_plus_y_test ( Coord a, point x, point y )
{
    for ( int i = 0; i < rdim; i++ )
    {
        *y++ += a * *x++;
    }
}

void vtkPowerCrustSurfaceReconstructionImpl::Vec_scale_test ( int n, Coord a, Coord *x )
{
    register Coord *xx = x, *xend = xx + n;
    
    while ( xx!=xend )
    {
        *xx *= a;
        xx++;
    }
}

double vtkPowerCrustSurfaceReconstructionImpl::sc ( basis_s *v,simplex *s, int k, int j )
{
    /* amount by which to scale up vector, for reduce_inner */
    if ( j < 10 )
    {
        double labound = logb ( v->sqa ) /2;
        sc_max_scale = exact_bits - labound - 0.66* ( k-2 )-1 - DELIFT;
        if ( sc_max_scale<1 )
        {
            sc_max_scale = 1;
        }
        
        if ( j == 0 )
        {
            int i;
            neighbor *sni;
            basis_s *snib;
            
            sc_ldetbound = DELIFT;
            
            sc_Sb = 0;
            for ( i=k-1,sni=s->neigh+k-1; i>0; i--,sni-- )
            {
                snib = sni->basis;
                sc_Sb += snib->sqb;
                sc_ldetbound += logb ( snib->sqb ) /2 + 1;
                sc_ldetbound -= snib->lscale;
            }
        }
    }
    if ( sc_ldetbound - v->lscale + logb ( v->sqb ) /2 + 1 < 0 )
    {
        return 0;
    }
    else
    {
        sc_lscale = ( int ) ( logb ( 2*sc_Sb/ ( v->sqb + v->sqa*b_err_min ) ) /2 ); // cast to int added by TJH
        if ( sc_lscale > sc_max_scale )
        {
            sc_lscale = ( int ) sc_max_scale; // cast added by TJH (is lscale really meant to be int, not double?)
        }
        else if ( sc_lscale < 0 ) sc_lscale = 0;
        v->lscale += sc_lscale;
        return two_to ( sc_lscale );
    }
}

int vtkPowerCrustSurfaceReconstructionImpl::reduce_inner ( basis_s *v, simplex *s, int k )
{
    point va = VA ( v ), vb = VB ( v );
    int i;
    basis_s *snibv;
    neighbor *sni;
    
    v->sqa = v->sqb = Norm2 ( vb );
    if ( k <= 1 )
    {
        memcpy ( vb,va,basis_vec_size );
        return 1;
    }
    for ( int j = 0; j < 250; j++ )
    {
        memcpy ( vb,va,basis_vec_size );
        for ( i=k-1,sni=s->neigh+k-1; i>0; i--,sni-- )
        {
            snibv = sni->basis;
            double dd = -Vec_dot ( VB ( snibv ),vb ) / snibv->sqb;
            Ax_plus_y ( dd, VA ( snibv ), vb );
        }
        v->sqb = Norm2 ( vb );
        v->sqa = Norm2 ( va );
        
        if ( 2*v->sqb >= v->sqa )
        {
            return 1;
        }
        
        Vec_scale_test ( rdim, sc ( v,s,k,j ),va );
        
        for ( i = k - 1, sni = s->neigh+k-1; i > 0; i--, sni-- )
        {
            snibv = sni->basis;
            double dd = -Vec_dot ( VB ( snibv ),va ) /snibv->sqb;
            dd = floor ( dd+0.5 );
            Ax_plus_y_test ( dd, VA ( snibv ), va );
        }
    }
    return 0;
}

void vtkPowerCrustSurfaceReconstructionImpl::trans ( point z, point p, point q )
{
    for ( int i = 0; i < pdim; i++ )
        z[i + rdim] = z[i] = p[i] - q[i];
}

void * vtkPowerCrustSurfaceReconstructionImpl::compute_3d_power_vv ( simplex *s, void *p )
{
    point v[MAXDIM];
    int inf = 0;
    int index = 0;
    double cc[3], cond, ta[4][4];
    edgesimp *pindex;
    
    if ( p )
    {
        if ( !s ) return NULL;
    }
    
    for ( int j = 0; j < cdim; j++ )
    {
        v[j] = s->neigh[j].vert;
        /* v[j] stores coordinates of j'th vertex of simplex s; j=0..3 */
        if ( v[j] == infinity ) /* means simplex s is on the convex hull */
        {
            inf = 1;
            continue; /* skip the rest of the for loop; process next vertex */
        }
        for ( int k = 0; k < 4; k++ )
        {
            ta[index][k] = v[j][k]/mult_up; /* restore original coords   */
        }
        index++;
    }
    
    /* if not faces on convex hull, process */
    if ( !inf )
    {
        /* build structure for each edge, including angle of intersection */
        for ( int k = 0; k < 6; k++ )
        {
            if ( s->edgestatus[k] == FIRST_EDGE ) /* not visited edge */
            {
                pindex = adjlist[ ( this->*site_num ) ( v[v1[k]] )].eptr;
                bool visited_edge = false;
                while ( pindex!= NULL )
                {
                    if ( pindex->pid == ( this->*site_num ) ( v[v2[k]] ) ) /* already in the list */
                    {
                        visited_edge = true;
                        break;
                    }
                    pindex = pindex->next;
                }
                
                if ( !visited_edge )
                {
                    double d = sqdist ( ta[v1[k]],ta[v2[k]] );
                    double r1 = SQ ( ta[v1[k]][0] ) +SQ ( ta[v1[k]][1] ) +SQ ( ta[v1[k]][2] )-ta[v1[k]][3];
                    double r2 = SQ ( ta[v2[k]][0] ) +SQ ( ta[v2[k]][1] ) +SQ ( ta[v2[k]][2] )-ta[v2[k]][3];
                    double e = 2 * sqrt ( r1 ) * sqrt ( r2 );
                    
                    edgesimp *newplist1;
                    newplist1 = ( edgesimp * ) malloc ( sizeof ( edgesimp ) );
                    newplist1->simp = s;
                    newplist1->kth = k;
                    newplist1->angle = ( r1+r2-d ) /e;
                    newplist1->pid = ( this->*site_num ) ( v[v1[k]] );
                    newplist1->next = adjlist[ ( this->*site_num ) ( v[v2[k]] )].eptr;
                    adjlist[ ( this->*site_num ) ( v[v2[k]] )].eptr = newplist1;
                    
                    edgesimp *newplist2;
                    newplist2 = ( edgesimp * ) malloc ( sizeof ( edgesimp ) );
                    newplist2->simp = s;
                    newplist2->kth = k;
                    newplist2->angle = ( r1+r2-d ) /e;
                    newplist2->pid = ( this->*site_num ) ( v[v2[k]] );
                    newplist2->next = adjlist[ ( this->*site_num ) ( v[v1[k]] )].eptr;
                    adjlist[ ( this->*site_num ) ( v[v1[k]] )].eptr = newplist2;
                    
                    s->edgestatus[k] = VISITED;
                }
            }
        }
        
        tetorthocenter ( ta[0], ta[1], ta[2], ta[3], cc, &cond );
        /* cc is the displacement of orthocenter from ta[0] */
        /* cond is the denominator ( orient2d ) value        */
        if ( cond != 0 ) /* ignore them if cond = 0 */
        {
            s->isVvNull = false;
            for ( int k = 0; k < 3; k++ )
            {
                s->vv[k] = ta[0][k]+cc[k];
            }
            s->status = VV;
        }
        else   /* if cond=0, s is SLIVER */
        {
            s->isVvNull = true;
            s->status = SLV;
        }
    }
    else   /* if on conv hull, ignore */
    {
        s->isVvNull = true;
        s->status = CNV;
    }
    
    return NULL;
}

void * vtkPowerCrustSurfaceReconstructionImpl::compute_axis ( simplex *s, void *p )
{
    point v[MAXDIM];
    point  point1, point2;
    int edgedata[6];
    int indices[6];
    
    if ( p )
    {
        if ( !s ) return NULL;
    }
    
    if ( ( s->status == CNV ) || ( s->status == SLV ) ) return NULL; /* skip inf faces */
    for ( int j = 0; j < cdim; j++ )
    {
        v[j] = s->neigh[j].vert;
    }
    
    for ( int k = 0; k < 6; k++ ) /* for each edge */
    {
        edgedata[k] = 0;
        if ( ( s->edgestatus[k]!=POW ) ) /* not dual to a power  face  */
        {
            point1 = v[v1[k]];
            point2 = v[v2[k]];
            int pindex= ( this->*site_num ) ( point1 );
            int qindex= ( this->*site_num ) ( point2 );
            if ( adjlist[pindex].label==IN && adjlist[qindex].label==IN )
            {
                if ( s->edgestatus[k]!=ADDAXIS )
                {
                }
                edgedata[k] = VALIDEDGE;
                indices[v1[k]] = pindex ;
                indices[v2[k]] = qindex ;
                s->edgestatus[k] = ADDAXIS;
            }
            /* now start adding triangles if present */
        }
    }
    
    if ( ( edgedata[0]==VALIDEDGE ) && ( edgedata[1]==VALIDEDGE ) && ( edgedata[3]==VALIDEDGE ) )
    {
        {
            vtk_medial_surface->GetPolys()->InsertNextCell ( 3 );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[0]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v2[1]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[3]] );
        }
    }
    if ( ( edgedata[1]==VALIDEDGE ) && ( edgedata[2]==VALIDEDGE ) && ( edgedata[5]==VALIDEDGE ) )
    {
        {
            vtk_medial_surface->GetPolys()->InsertNextCell ( 3 );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[1]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v2[2]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[5]] );
        }
    }
    if ( ( edgedata[0]==VALIDEDGE ) && ( edgedata[2]==VALIDEDGE ) && ( edgedata[4]==VALIDEDGE ) )
    {
        {
            vtk_medial_surface->GetPolys()->InsertNextCell ( 3 );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[0]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v2[2]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[4]] );
        }
    }
    if ( ( edgedata[3]==VALIDEDGE ) && ( edgedata[4]==VALIDEDGE ) && ( edgedata[5]==VALIDEDGE ) )
    {
        {
            vtk_medial_surface->GetPolys()->InsertNextCell ( 3 );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[3]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v2[4]] );
            vtk_medial_surface->GetPolys()->InsertCellPoint ( indices[v1[5]] );
        }
    }
    return NULL;
}

void vtkPowerCrustSurfaceReconstructionImpl::construct_face ( simplex *s, short k )
{
    site edge0, edge1, nextv, remv, prevv,outsite,insite;
    simplex *prevs, *nexts;
    int j, numedges, l1, l2, nk, l, nedge0=0, nedge1=0, nremv=0, nnextv=0, i;
    char indface[1024][32];  /* the indices of the face */
    
    double plane[3][3];
    double outpole[3],inpole[3];
    
    edge0 = s->neigh[v1[k]].vert;
    edge1 = s->neigh[v2[k]].vert;
    
    if ( adjlist[ ( this->*site_num ) ( edge0 )].label==OUT )
    {
        outsite=edge0;
        insite=edge1;
    }
    else
    {
        outsite=edge1;
        insite=edge0;
    }
    
    for ( j=0; j<3; j++ )
    {
        outpole[j]=outsite[j]/mult_up;
        inpole[j]=insite[j]/mult_up;
    }
    
    nextv = s->neigh[v3[k]].vert;
    /* nextv is the opposite vtx of the next simplex */
    remv = s->neigh[v4[k]].vert;
    /* remv is a vtx of the next simplex with edge0, edge1 */
    prevv = remv;
    /* prevv is the vtx shared by prevs and nexts besides edge0, edge1 */
    
    /* construct its dual power face */
    s->edgestatus[k]=POW;
    
    /* visit the next simplex */
    prevs = s;
    nexts = s->neigh[v3[k]].simp;
    
    numedges=0;
    while ( nexts != s )
    {
        if ( nexts->status == CNV )
        {
            break;
        }
        else
        {
            if ( prevs->status != POLE_OUTPUT )
            {
                /* this vertex is not yet output */
                prevs->status = POLE_OUTPUT;
                prevs->poleindex = num_vtxs++;
                // TJH: PC contains the points for the powercrust surface
                // so we hijack the data and pipe it to our structure
                {
                    float vp[3];
                    vp[0]=prevs->vv[0];
                    vp[1]=prevs->vv[1];
                    vp[2]=prevs->vv[2];
                    vtk_output->GetPoints()->InsertNextPoint ( vp );
                }
            }
            
            if ( numedges<3 )
            {
                plane[numedges][0]=prevs->vv[0];
                plane[numedges][1]=prevs->vv[1];
                plane[numedges][2]=prevs->vv[2];
            }
            
            sprintf ( indface[numedges], "%ld ", prevs->poleindex );
            numedges++;
            /* find edgenumber k of nexts for this edge */
            for ( l=0; l<4; l++ )
            {
                if ( nexts->neigh[l].vert==edge0 )
                {
                    nedge0 = l;
                    continue;
                }
                else if ( nexts->neigh[l].vert==edge1 )
                {
                    nedge1 = l;
                    continue;
                }
                else if ( nexts->neigh[l].vert==prevv )
                {
                    nremv = l;
                    continue;
                }
                else if ( nexts->neigh[l].vert==nextv )
                {
                    nnextv = l;
                    continue;
                }
                else
                {
                    nnextv = l;
                }
            }
            
            if ( nedge0 > nedge1 )
            {
                l1 = nedge1;
                l2 = nedge0;
            }
            else
            {
                l2 = nedge1;
                l1 = nedge0;
            }
            if ( l1==0 )
            {
                if ( l2==1 ) nk = 0;
                else if ( l2==2 ) nk = 1;
                else nk = 2;
            }
            else if ( l1==1 )
            {
                if ( l2==2 ) nk = 3;
                else nk = 4;
            }
            else nk = 5;
            /* found nk for the edge */
            nexts->edgestatus[nk]=POW; /* record that it's visited */
            /* visit next simplex (opposite vertex ns )*/
            prevs = nexts;
            prevv = nexts->neigh[nnextv].vert;
            nexts = nexts->neigh[nremv].simp;
        }
    }
    
    if ( prevs->status != POLE_OUTPUT )
    {
        prevs->status = POLE_OUTPUT;
        prevs->poleindex = num_vtxs++;
        // TJH: PC contains the points for the powercrust surface
        // so we hijack the data and pipe it to our structure
        {
            float vp[3];
            vp[0]=prevs->vv[0];
            vp[1]=prevs->vv[1];
            vp[2]=prevs->vv[2];
            vtk_output->GetPoints()->InsertNextPoint ( vp );
        }
    }
    
    if ( numedges<3 )
    {
        plane[numedges][0]=prevs->vv[0];
        plane[numedges][1]=prevs->vv[1];
        plane[numedges][2]=prevs->vv[2];
        
    }
    sprintf ( indface[numedges],"%ld ",prevs->poleindex );
    
    numedges++;
    
    vtk_output->GetPolys()->InsertNextCell ( numedges );
    
    if ( !correct_orientation ( plane[0],plane[1],plane[2],inpole,outpole ) )
        for ( i = numedges - 1; i >= 0; i-- )
        {
            {
                vtk_output->GetPolys()->InsertCellPoint ( atoi ( indface[i] ) );
            }
        }
    else
    {
        for ( i = 0; i < numedges; i++ )
        {
            {
                vtk_output->GetPolys()->InsertCellPoint ( atoi ( indface[i] ) );
            }
        }
    }
}

int vtkPowerCrustSurfaceReconstructionImpl::correct_orientation ( double *p1,double *p2,double *p3,double *inp,double *outp )
{
    double normal[3];
    double v1[3],v2[3];
    double xcross,ycross,zcross;
    int numplus=0,numminus=0;
    
    normal[0]=outp[0]-inp[0];
    normal[1]=outp[1]-inp[1];
    normal[2]=outp[2]-inp[2];
    
    v1[0]=p2[0]-p1[0];
    v1[1]=p2[1]-p1[1];
    v1[2]=p2[2]-p1[2];
    
    v2[0]=p3[0]-p2[0];
    v2[1]=p3[1]-p2[1];
    v2[2]=p3[2]-p2[2];
    
    xcross=v1[1]*v2[2]-v1[2]*v2[1];
    ycross=v1[2]*v2[0]-v1[0]*v2[2];
    zcross=v1[0]*v2[1]-v1[1]*v2[0];
    
    if ( ( xcross*normal[0] ) > 0 )
        numplus++;
    else
        numminus++;
    
    
    if ( ( ycross*normal[1] ) > 0 )
        numplus++;
    else
        numminus++;
    
    
    if ( ( zcross*normal[2] ) > 0 )
        numplus++;
    else
        numminus++;
    
    if ( numplus > numminus )
        return 1;
    else
        return 0;
    
}

//=====================================================================

//vtkCxxRevisionMacro ( vtkPowerCrustSurfaceReconstruction, "$Revision: 1.2 $" );
vtkStandardNewMacro ( vtkPowerCrustSurfaceReconstruction );

vtkPowerCrustSurfaceReconstruction::vtkPowerCrustSurfaceReconstruction()
{
    this->MedialSurface = vtkPolyData::New();
    EstimateR = 0.6;
    MultlUp = 1000000;
}

vtkPowerCrustSurfaceReconstruction::~vtkPowerCrustSurfaceReconstruction()
{
    this->MedialSurface->Delete();
}

void vtkPowerCrustSurfaceReconstruction::Error ( const char *message )
{
    throw vtkPowerCrustSurfaceReconstructionException ( message );
}

int vtkPowerCrustSurfaceReconstruction::FillInputPortInformation ( int, vtkInformation *info )
{
    info->Set ( vtkAlgorithm::INPUT_REQUIRED_DATA_TYPE(), "vtkPolyData" );
    return 1;
}

int vtkPowerCrustSurfaceReconstruction::RequestData ( vtkInformation* vtkNotUsed ( request ), vtkInformationVector** InputVector, vtkInformationVector* OutputVector )
{
    vtkPowerCrustSurfaceReconstructionImpl PowerCrustImpl;
    PowerCrustImpl.pcInit();
    
    vtkInformation *InInfo = InputVector[0]->GetInformationObject ( 0 );
    vtkInformation *OutInfo = OutputVector->GetInformationObject ( 0 );
    
    // get the input and ouptut
    vtkPolyData *input = vtkPolyData::SafeDownCast ( InInfo->Get ( vtkDataObject::DATA_OBJECT() ) );
    vtkPolyData *output = vtkPolyData::SafeDownCast ( OutInfo->Get ( vtkDataObject::DATA_OBJECT() ) );
    
    // make sure output is initialised
    // create some points for the output
    {
        vtkPoints *points = vtkPoints::New();
        output->SetPoints ( points );
        points->Delete();
    }
    
    {
        vtkCellArray *polys = vtkCellArray::New();
        output->SetPolys ( polys );
        polys->Delete();
    }
    
    {
        vtkPoints *points = vtkPoints::New();
        this->MedialSurface->SetPoints ( points );
        points->Delete();
    }
    
    {
        vtkCellArray *polys = vtkCellArray::New();
        this->MedialSurface->SetPolys ( polys );
        polys->Delete();
    }
    
    {
        vtkFloatArray *pole_weights = vtkFloatArray::New();
        pole_weights->SetNumberOfComponents ( 1 );
        this->MedialSurface->GetPointData()->SetScalars ( pole_weights );
        pole_weights->Delete();
    }
    
    PowerCrustImpl.vtk_input = input;
    PowerCrustImpl.vtk_output = output;
    PowerCrustImpl.vtk_medial_surface = this->MedialSurface;
    PowerCrustImpl.our_filter = this;
    
    this->MultlUp = input->GetPoints()->GetNumberOfPoints() * 10;
    
    try
    {
        PowerCrustImpl.adapted_main ( this->MultlUp );
        this->MedialSurface->Modified();
    }
    catch ( vtkPowerCrustSurfaceReconstructionException& e )
    {
        std::cerr << "An error happend: " << e.what() << "\n";
    }
    
    PowerCrustImpl.freeAll();
    return 1;
}

void vtkPowerCrustSurfaceReconstruction::PrintSelf ( ostream& os, vtkIndent indent )
{
    this->Superclass::PrintSelf ( os, indent );
}

void vtkPowerCrustSurfaceReconstruction::ExecuteInformation()
{
    if ( this->GetInput() == NULL )
    {
        vtkErrorMacro ( "No Input" );
        return;
    }
}

//=====================================================================
