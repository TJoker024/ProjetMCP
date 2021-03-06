// Pierre ortegat , Alexandre rucquoy , Alexis Van den bogaert

// Le type de données pour les rectangles.
// Remplacez-le par votre définition de rectangle.
// Vous pouvez en introduire d'autres si vous le jugez pertinent.
datatype rData = Rectangle(x: int, y: int, w: int, h: int)

predicate method okRekt(t: rData)
{
    t.x >= 0 && t.y >= 0 && t.h > 0 && t.w > 0
}

function absRekt(t: rData): bool
{
    okRekt(t)
}
/*
  Permet de vérifier que 2 rectangles sont voisins
  @Pre: 2 rectangles a et b valides
*/
function method isNeighbours(a: rData, b: rData) : bool 
  requires okRekt(a) && okRekt(b)
{
    (a.x + a.w == b.x && a.y == b.y) || (a.y + a.h == b.y && a.x == b.x)
}

/*
Permet de vérifier si 2 rectangles sont fusionables 
@Pre: 2 rectangles a et b valides
*/
function method canMerge(a: rData, b: rData) : bool
  requires okRekt(a) && okRekt(b)
{
  if   isNeighbours(a,b) || isNeighbours(b,a) then
    if a.x == b.x then
      a.w == b.w
    else if a.y == b.y then
      a.h == b.h
    else
      false
  else
    false
  //( ( isNeighbours(a,b) || isNeighbours(b,a) ) && (a.w == b.w || a.h == b.h) )
}

/*
Fusionne 2 rectangle
@Pre: 2 rectangles a et b valides et fusionnables
*/
function method merge(a: rData, b: rData) : rData
  requires okRekt(a) && okRekt(b) && (canMerge(a,b) || canMerge(b,a))
{
    if a.y == b.y then // si les rectangle sont cote a cote 
      Rectangle(min(a.x,b.x), min(a.y, b.y), a.w+b.w, a.h)
    else
      if a.x == b.x then // si les rectangles sont l'un au dessus de l'autre
        Rectangle(min(a.x, b.x), min(a.y, b.y), a.w, a.h + b.h)
      else
        Rectangle(-1,-1,-1,-1)
}

function method min(a: int, b:int) : int
{
    if a<b then a else b
}

class Couverture {

    var TuillesTab: array<rData>; // tableau de rectangle
    // autres champs de la classe
    var indexArray: int; // variable utilisée pour la fusion de rectangle
	//Nombre de rectangle 
    var nbrRekt: nat; 
    ghost var previousNbrRekt: nat ; // Permet de prouver le décrémentation du nombre de rectangles

    // Ceci est votre invariant de représentation.
    // C'est plus simple d'avoir ok() dans les pre et les posts que le le recoper à chaque fois.
    predicate ok()
        reads this, TuillesTab
    {
        TuillesTab != null
        
    }

    constructor (qs: array<rData>)
        requires qs != null
        modifies this // forcément ;-)
        ensures ok()
    {
        TuillesTab := qs;
        nbrRekt:=TuillesTab.Length;// On initialise nbrRekt au nombre rectangle recu en paramètre
        previousNbrRekt:=nbrRekt+1;
    }
    /*
      Vérifie si le point supérieur gauche est contenu dans la couverture
      @pre un rectangles a valide et tuilles tab != null
    */
    method contains( a: rData) returns(retVal:bool)
    requires TuillesTab!=null
    requires ok()
    requires okRekt(a)
    ensures ok()
    {
      retVal:=false;
      var i: int :=TuillesTab.Length-1 ;
      var compRekt: rData;
      while i>=0 // on parcourt tout les rectangles 
      invariant i <TuillesTab.Length
      invariant TuillesTab !=null
      decreases i
      {
        compRekt:= TuillesTab[i]; // Rectangle de la couverture
        if compRekt.x<= a.x <=compRekt.x+compRekt.w &&  compRekt.y<= a.y <=compRekt.y+compRekt.h 
        {
          retVal:=true;
        }
        i:=i-1;
      }

    }

    method optimize()
        requires ok()
        modifies this
        ensures ok()
    {
        indexArray := TuillesTab.Length;
        var bigArray := new rData[TuillesTab.Length * 2];// On crée un tableau dont la 1ère moitié contient les rectangles et dont la deuxième moitié contiendra les rectangles fusionnés
        var i : int := 0;
        while i < TuillesTab.Length
          invariant TuillesTab != null
          invariant 0 <= i <= TuillesTab.Length
          invariant TuillesTab.Length <= bigArray.Length
          invariant TuillesTab.Length<= indexArray <= bigArray.Length
          invariant forall j :: 0 <= j < i ==> bigArray[j] == TuillesTab[j]
        {
          bigArray[i] := TuillesTab[i];
          i := i+1;
        }
        var flag : bool := true;
        var nbrBoucl: int := bigArray.Length*2; // Permet de certifier que la boucle ne fera pas plus de tours que 2 fois la taille de l'array 
        while flag && nbrRekt >0 && nbrBoucl>0  // S'arrete si on ne peut plus rien merge, si il n'y a plus de rectangles , si on a bouclé plus de 2 fois la taille de big array
          decreases nbrBoucl
          invariant bigArray!=null
          invariant TuillesTab!=null
          invariant TuillesTab.Length<= indexArray <= bigArray.Length
        {
          flag := improve(bigArray);
          nbrBoucl:= nbrBoucl-1;
      	}
        //replace tuile tab with a small array
        //getting the sizee for the new array
        var sizeNew : int := 0;
        i := 0;
        while i < bigArray.Length { // On regarde combien de rectangle valide il reste dans bigArray
          if bigArray[i].x != -1 {
            sizeNew := 1 + sizeNew;
          }
          i := i +1;
        }
        //assigning the new array
        var result := new rData[sizeNew];
        var count : int := 0;
        i := 0;
        while i < bigArray.Length && count <sizeNew // On crée un tableau qui contient la couverture optimale
        invariant 0<=i<=bigArray.Length
        invariant 0<= count <= result.Length;
        {
          if bigArray[i].x != -1 {
            result[count] :=
             bigArray[i];
            count := count +1;
          }
          i := i +1;
        }
        TuillesTab := result;
    }
    /*
    True si on a réussi à fusionner au moins 2 rectangles et renvoie false sinon ( ce qui permet la l'arret ) 
    */
    method improve(inputArray: array<rData>) returns(retVal: bool)
      modifies inputArray
      modifies this
      requires inputArray != null
      requires TuillesTab!=null
      requires TuillesTab.Length<=indexArray <= inputArray.Length
      requires ok()
      ensures TuillesTab!=null
     ensures TuillesTab.Length<=indexArray <= inputArray.Length
     ensures (previousNbrRekt==nbrRekt+1 || retVal==false)
    {
      retVal := false;
      var i : int := 0;
      var tempBool : bool;
      while i < inputArray.Length-1 && nbrRekt >0
      invariant TuillesTab!=null
      invariant TuillesTab.Length<= indexArray <=inputArray.Length
      invariant 0 <= i <= inputArray.Length 
      invariant (previousNbrRekt==nbrRekt+1 || retVal==false)
      {
        var j : int := i+1;
        while j < inputArray.Length && nbrRekt >0
        	invariant i+1 <= j <= inputArray.Length
          invariant TuillesTab!=null
          invariant TuillesTab.Length<= indexArray <= inputArray.Length
          invariant (previousNbrRekt==nbrRekt+1 || retVal==false)
        {
          retVal:=tryMerge( inputArray,i,j); // on essaie de fusionner 2 rectangles
          if (!retVal){ previousNbrRekt:=nbrRekt;}
        
          j:= j+1;
        }//forall
        i:= i+1;
      }//forall
    }//improve

    /*
    Tente de fusionner les 2 rectangles fournis en en paramètres et return true en cas de succès , false sinon
    */
    method tryMerge(inputArray: array<rData>, i:int, j:int) returns (retVal: bool)
    requires TuillesTab!=null
   	requires inputArray !=null
   	requires 0<=i<inputArray.Length
   	requires 0<=j<inputArray.Length
   	requires nbrRekt >0
   	modifies this
   	modifies inputArray
    requires 0<=TuillesTab.Length<= indexArray <= inputArray.Length
   	ensures (previousNbrRekt==nbrRekt+1 || retVal==false)
    ensures TuillesTab!=null
    ensures TuillesTab.Length<= indexArray <= inputArray.Length
   	decreases nbrRekt

   	{
   		retVal:=false;
  		if(okRekt(inputArray[i]) && okRekt(inputArray[j]) && indexArray<inputArray.Length){ // Vérifie que les 2 rectangles sont valide
  	   if(canMerge(inputArray[i], inputArray[j])){ // vérifie que les 2 rectangles sont fusionnables
         inputArray[indexArray] := merge(inputArray[i], inputArray[j]);
         indexArray := indexArray + 1;
         inputArray[i] := Rectangle(-1,0,0,0);//on remplace les anciens rectangles par des rectangles non valides
         inputArray[j] := Rectangle(-1,0,0,0);
         previousNbrRekt:=nbrRekt; 
         nbrRekt:=nbrRekt-1; // on décrémente le nombre de rectangles de 1 
         retVal:=true;// on return true
   			}
   		}
   	}

    method dump()
        requires ok()
    {
        var i := 0;
        var first := true;
        print "[ ";
        while i < TuillesTab.Length
        {
            if !first { print ", "; }
            print TuillesTab[i];
            i := i + 1;
            first := false;
        }
        print " ]\n";
    }

}
method Main()
{
    // Vous devez écrire ici trois tests de votre méthode optimize
    var g := new rData[3];
    g[1], g[2] := Rectangle(1,1,1,1), Rectangle(2,1,1,1);

    //simple basic test
    var m := new Couverture(g);
    m.optimize();
    print "\n";
    print m;
    m.dump();
    print "\n";

    //testing a complete rectangle
    var h := new rData[3];
    h[0], h[1], h[2] := Rectangle(1,1,1,1), Rectangle(2,1,1,1), Rectangle(1,2,2,1);
    var i := new Couverture(h);
    i.optimize();
    print "\n";
    print i;
    i.dump();
    print "\n";

    //testing with a "holled" rectangle
    var j := new rData[5];
    j[0], j[1], j[2], j[3], j[4] := Rectangle(1,1,2,1), Rectangle(3,1,1,2), Rectangle(1,3,1,1), Rectangle(2,2,1,2), Rectangle(3,3,1,1);
    var k := new Couverture(j);
    k.optimize();
    print "\n";
    print k;
    k.dump();
    print "\n";
}